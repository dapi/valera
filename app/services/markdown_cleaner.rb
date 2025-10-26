# frozen_string_literal: true

# MarkdownCleaner - модуль для очистки и форматирования Markdown текста
#
# Назначение:
# - Очистка и исправление некорректного Markdown
# - Конвертация в формат, совместимый с Telegram Bot API
# - Защита от XSS и malicious content через санитизацию
# - Обработка ошибок форматирования с graceful degradation
#
# Использует Kramdown (pure Ruby) + Sanitize gem для безопасной обработки
#
# @see docs/requirements/tdd/TDD-003-markdown-cleaner-implementation.md
# @see docs/gems/markdown-parser-comparison.md
class MarkdownCleaner

  # Конфигурация Kramdown для безопасной обработки Markdown
  # Отключает HTML теги и включает безопасные entity output
  KRAMDOWN_SAFE_OPTIONS = {
    remove_block_html_tags: true,      # Удалить HTML блоки
    remove_span_html_tags: true,       # Удалить HTML спаны
    parse_block_html: false,           # Не парсить HTML блоки
    parse_span_html: false,            # Не парсить HTML спаны
    entity_output: :symbolic           # Безопасные HTML entities
  }.freeze

  # Конфигурация Sanitize для очистки HTML
  # White-list подход - только безопасные элементы для Telegram
  SANITIZE_CONFIG = {
    elements: %w[strong em code a],           # Разрешенные HTML элементы
    attributes: { 'a' => ['href'] },          # Разрешенные атрибуты
    protocols: { 'a' => { 'href' => %w[http https] } } # Безопасные протоколы
  }.freeze

  # Максимальная длина сообщения для Telegram API
  MAX_MESSAGE_LENGTH = 4096

  # Основной public API метод для очистки Markdown
  #
  # @param text [String] Markdown текст для очистки
  # @param options [Hash] дополнительные опции
  # @option options [Boolean] :strict_mode (false) строгий режим обработки ошибок
  # @option options [Boolean] :preserve_links (true) сохранять ссылки
  #
  # @return [String] очищенный Markdown текст, готовый для Telegram API
  #
  # @example
  #   MarkdownCleaner.clean_for_telegram('**Hello** *world*!')
  #   #=> '**Hello** *world*!'
  #
  # @example с опасным контентом
  #   MarkdownCleaner.clean_for_telegram('**Hello** <script>alert(1)</script>!')
  #   #=> '**Hello** !'
  def self.clean_for_telegram(text, options = {})
    return '' if text.nil? || text.empty?

    begin
      # 0. Проверяем нужно ли исправление (более консервативный подход)
      # Только если есть очевидные проблемы, применяем исправление
      if has_obvious_broken_formatting?(text)
        preprocessed_text = fix_broken_formatting(text)
        # 1. Безопасный парсинг Markdown через Kramdown
        html = safe_parse_markdown(preprocessed_text)
      else
        # Если проблем нет, парсим как есть
        html = safe_parse_markdown(text)
      end

      # 2. Очистка HTML через Sanitize gem
      clean_html = sanitize_html(html)

      # 3. Конвертация обратно в Telegram Markdown формат
      result = convert_to_telegram_format(clean_html, options)

      # 4. Усечение до лимита Telegram
      truncate_to_telegram_limit(result)

    rescue => e
      # Fallback к plain text при ошибках
      puts "MarkdownCleaner error: #{e.message} - Input: #{text[0..99]}"
      fallback_to_plain_text(text)
    end
  end

  private

  # Безопасный парсинг Markdown через Kramdown с защищенными опциями
  #
  # @param text [String] Markdown текст
  # @return [String] HTML результат
  def self.safe_parse_markdown(text)
    require 'kramdown' unless defined?(Kramdown)
    Kramdown::Document.new(text, KRAMDOWN_SAFE_OPTIONS).to_html
  end

  # Санитизация HTML через Sanitize gem
  # Удаляет небезопасные элементы и атрибуты
  #
  # @param html [String] HTML для очистки
  # @return [String] очищенный HTML
  def self.sanitize_html(html)
    require 'sanitize' unless defined?(Sanitize)
    Sanitize.clean(html, SANITIZE_CONFIG)
  end

  # Конвертация очищенного HTML обратно в Telegram Markdown формат
  # Обрабатывает только поддерживаемые Telegram элементы
  #
  # @param clean_html [String] очищенный HTML
  # @param options [Hash] опции конвертации
  # @return [String] Markdown текст для Telegram
  def self.convert_to_telegram_format(clean_html, options = {})
    return '' if clean_html.nil? || clean_html.empty?

    # Базовая конвертация HTML -> Markdown
    # Поддерживаемые Telegram элементы: **bold**, *italic*, `code`, [links](url)

    result = clean_html.dup

    # Обрабатываем ссылки в первую очередь, чтобы избежать конфликтов
    result.gsub!(/<a[^>]*href="([^"]*)"[^>]*>(.*?)<\/a>/i) do |match|
      url = $1
      text = $2
      # Проверяем безопасные протоколы
      if url.match?(/\Ahttps?:\/\//)
        "[#{text}](#{url})"
      else
        text # Возвращаем только текст для небезопасных URL
      end
    end

    # Заменяем остальные HTML элементы на Markdown
    result.gsub!(/<strong>(.*?)<\/strong>/im) { "**#{$1}**" }      # **bold**
    result.gsub!(/<em>(.*?)<\/em>/im) { "*#{$1}*" }                 # *italic*
    result.gsub!(/<code>(.*?)<\/code>/im) { "`#{$1}`" }            # `code`

    # Параграфы и переносы строк
    result.gsub!(/<p>(.*?)<\/p>/im) { "#{$1}\n\n" }
    result.gsub!(/<br\s*\/?>/i, "\n")

    # Дополнительная очистка от оставшихся HTML тегов
    result.gsub!(/<[^>]*>/, '')

    # Убираем лишние пробелы и переносы
    result.strip.gsub(/\n{3,}/, "\n\n")
  end

  # Предварительная обработка и исправление сломанного markdown форматирования
  # Исправляет незакрытые теги, сломанные ссылки и другие проблемы
  # Более консервативный подход - исправляем только очевидные проблемы
  #
  # @param text [String] исходный markdown текст
  # @return [String] исправленный markdown текст
  def self.fix_broken_formatting(text)
    return '' if text.nil? || text.empty?

    result = text.dup

    # 1. Исправляем сломанные ссылки [text]()
    result.gsub!(/\[([^\]]*)\]\(\s*\)/) do |match|
      text = $1
      text.empty? ? '' : text # Возвращаем только текст если ссылка сломана
    end

    # 2. Исправляем множественные *** (common mistake)
    result.gsub!(/\*{3,}/) { '**' } # Превращаем *** в **bold**

    # 3. Исправляем очевидно незакрытые теги только в конце текста
    # Это консервативный подход - не испортим правильный markdown
    result = fix_unclosed_tags_at_end(result)

    # 4. Удаляем standalone символы форматирования
    result.gsub!(/\*\s*\*/, '') # standalone **
    result.gsub!(/\*\s*\*/, '') # standalone *
    result.gsub!(/__\s*__/, '') # standalone __
    result.gsub!(/`\s*`/, '') # standalone `

    result.strip
  end

  # Исправление незакрытых тегов только в конце текста (более безопасный подход)
  def self.fix_unclosed_tags_at_end(text)
    result = text.dup

    # Проверяем конец текста на незакрытые теги
    # Используем count для точного определения незакрытых тегов
    bold_count = result.scan(/\*\*/).length
    asterisk_count = result.scan(/\*(?!\*)/).length
    underscore_count = result.scan(/__/).length
    backtick_count = result.scan(/`/).length

    # Добавляем закрывающие теги только если нечетное количество
    if bold_count.odd?
      result += '**'
    end
    if asterisk_count.odd?
      result += '*'
    end
    if underscore_count.odd?
      result += '__'
    end
    if backtick_count.odd?
      result += '`'
    end

    result
  end

  # Проверка наличия очевидных проблем в markdown
  # Только очевидные проблемы: незакрытые теги в конце, сломанные ссылки
  #
  # @param text [String] markdown текст
  # @return [Boolean] true если есть очевидные проблемы
  def self.has_obvious_broken_formatting?(text)
    return false if text.nil? || text.empty?

    # 1. Незакрытые теги в самом конце текста
    return true if text.end_with?('**') && text.count('**') == 1
    return true if text.end_with?('*') && text.count('*') == 1
    return true if text.end_with?('__') && text.count('__') == 1
    return true if text.end_with?('`') && text.count('`') == 1

    # 2. Сломанные ссылки
    return true if text.match?(/\[[^\]]*\]\(\s*\)/)

    # 3. Множественные звезды
    return true if text.match?(/\*{3,}/)

    false
  end

  # Усечение сообщения до лимита Telegram (4096 символов)
  #
  # @param text [String] текст для усечения
  # @return [String] усеченный текст
  def self.truncate_to_telegram_limit(text)
    return text if text.length <= MAX_MESSAGE_LENGTH

    # Усекаем с запасом и добавляем многоточие
    text.truncate(MAX_MESSAGE_LENGTH - 3, omission: '...')
  end

  # Fallback к plain text при критических ошибках
  # Удаляет все Markdown символы и возвращает чистый текст
  #
  # @param text [String] исходный текст
  # @return [String] plain текст
  def self.fallback_to_plain_text(text)
    return '' if text.nil? || text.empty?

    # Удаляем Markdown символы и HTML теги
    plain = text
      .gsub(/`[^`]*`/, '\\1')           # Удаляем `code` разметку
      .gsub(/\*\*[^*]*\*\*/, '\\1')     # Удаляем **bold** разметку
      .gsub(/\*[^*]*\*/, '\\1')         # Удаляем *italic* разметку
      .gsub(/__[^_]*__/, '\\1')          # Удаляем __italic__ разметку
      .gsub(/<[^>]*>/, '')              # Удаляем HTML теги
      .strip

    truncate_to_telegram_limit(plain)
  end
end