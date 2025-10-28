# frozen_string_literal: true

# Сервис для очистки и оптимизации Markdown для Telegram
#
# Преобразует Markdown форматирование в совместимый с Telegram формат,
# удаляя неподдерживаемые элементы и оптимизируя отображение.
#
# @example Очистка сообщения для Telegram
#   cleaned = MarkdownCleanerService.clean_for_telegram("**Bold** text")
#   #=> "*Bold* text"
#
# @example Очистка с сохранением перевода строк
#   cleaned = MarkdownCleanerService.clean_with_line_breaks("Line 1\nLine 2")
#   #=> "Line 1\nLine 2"
#
# @see TSD-003-markdown-cleaner-implementation.md - техническая спецификация
# @author Danil Pismenny
# @since 0.1.0
class MarkdownCleanerService
  include ErrorLogger

  # Поддерживаемые Telegram markdown элементы
  TELEGRAM_SUPPORTED = {
    bold: '*',
    italic: '_',
    inline_code: '`',
    code_block: '```'
  }.freeze

  # Неподдерживаемые элементы для замены
  UNSUPPORTED_REPLACEMENTS = {
    /\*\*/ => '*', # Double to single asterisk
    /__\s*([^_]+)\s*__/m => '_\1_', # Double underscores to single
    /~~([^~]+)~~/ => '\1', # Remove strikethrough
    /\[([^\]]+)\]\([^)]+\)/ => '\1', # Links to text only
    /^\#{4,}(.+)$/m => '\1', # Headers to plain text
    /^\#{1,3}\s+(.+)$/m => '*\1*', # H1-H3 to bold
    /^\* (.+)$/m => '• \1', # Bullet points
    /^\d+\.?\s*(.+)$/m => '\1', # Numbered lists
    /^> (.+)$/m => '\1', # Blockquotes
    /^\|.*\|$/m => '' # Remove table lines
  }.freeze

  class << self
    # Основной метод очистки Markdown для Telegram
    #
    # @param text [String] исходный текст с Markdown
    # @param preserve_line_breaks [Boolean] сохранять переносы строк
    # @return [String] очищенный текст для Telegram
    def clean_for_telegram(text, preserve_line_breaks: false)
      return '' if text.blank?

      # Оптимизированная версия с минимальным созданием временных строк
      text = apply_basic_replacements(text)
      text = handle_code_blocks(text)
      text = handle_formatting(text)
      text = handle_lists_optimized(text)
      text = clean_extra_whitespace(text)
      text = handle_line_breaks(text, preserve_line_breaks)

      text.strip
    rescue StandardError => e
      log_error(e, { text: text, service: 'MarkdownCleanerService' })
      text # Return original text if cleaning fails
    end

    # Очистка с сохранением переносов строк (для многострочных сообщений)
    #
    # @param text [String] исходный текст
    # @return [String] очищенный текст с переносами
    def clean_with_line_breaks(text)
      clean_for_telegram(text, preserve_line_breaks: true)
    end

    # Очистка для однострочных сообщений
    #
    # @param text [String] исходный текст
    # @return [String] очищенный однострочный текст
    def clean_single_line(text)
      clean_for_telegram(text, preserve_line_breaks: false)
    end

    # Проверяет, содержит ли текст неподдерживаемые элементы
    #
    # @param text [String] текст для проверки
    # @return [Boolean] true если есть неподдерживаемые элементы
    def has_unsupported_elements?(text)
      return false if text.blank?

      unsupported_patterns = [
        /\*\*/, # Double asterisks
        /__/, # Double underscores
        /~~/, # Strikethrough
        /\[.*\]\(.*\)/, # Links
        /^\#{1,}/, # Headers
        /^\|.*\|$/, # Tables
        /^> / # Blockquotes
      ]

      unsupported_patterns.any? { |pattern| text.match?(pattern) }
    end

    private

    # Применяет базовые замены неподдерживаемых элементов
    #
    # @param text [String] текст для обработки
    # @return [String] обработанный текст
    def apply_basic_replacements(text)
      UNSUPPORTED_REPLACEMENTS.each do |pattern, replacement|
        text.gsub!(pattern, replacement)
      end
      text
    end

    # Обрабатывает кодовые блоки
    #
    # @param text [String] текст для обработки
    # @return [String] обработанный текст
    def handle_code_blocks(text)
      # Preserve inline code
      text.gsub!(/`([^`]+)`/, '`\1`')

      # Handle code blocks - convert to inline code for short blocks
      text.gsub!(/```(\w+)?\n(.+?)\n```/m) do |match|
        code_content = $2.strip
        if code_content.length < 50
          "`#{code_content}`"
        else
          "```\n#{code_content}\n```"
        end
      end

      text
    end

    # Обрабатывает форматирование (жирный, курсив)
    #
    # @param text [String] текст для обработки
    # @return [String] обработанный текст
    def handle_formatting(text)
      # Ensure proper bold formatting
      text.gsub!(/\*([^*\n]+)\*/, '*\1*')

      # Ensure proper italic formatting
      text.gsub!(/_([^_\n]+)_/, '_\1_')

      # Fix nested formatting
      text.gsub!(/\*_([^*_]+)_\*/, '*_\1_*')
      text.gsub!(/_\*([^*_]+)\*_/, '_*\1*_')

      text
    end

    # Обрабатывает списки (оптимизированная версия)
    #
    # @param text [String] текст для обработки
    # @return [String] обработанный текст
    def handle_lists_optimized(text)
      # Используем gsub! для работы с одной строкой вместо split/map/join
      text.gsub!(/^\* (.+)$/, '• \1')
      text.gsub!(/^\d+\.?\s*(.+)$/, '\1')
      text.gsub!(/^-\s*(.+)$/, '• \1')
      text
    end

    # Обрабатывает списки (оригинальная версия для сложных случаев)
    #
    # @param text [String] текст для обработки
    # @return [String] обработанный текст
    def handle_lists(text)
      lines = text.split("\n")
      processed_lines = lines.map do |line|
        case line
        when /^\* (.+)/
          "• #{$1}"
        when /^\d+\.?\s*(.+)/
          "#{$1}"
        when /^-\s*(.+)/
          "• #{$1}"
        else
          line
        end
      end
      processed_lines.join("\n")
    end

    # Очищает лишние пробелы и пустые строки
    #
    # @param text [String] текст для обработки
    # @return [String] обработанный текст
    def clean_extra_whitespace(text)
      # Remove multiple consecutive empty lines
      text.gsub!(/\n{3,}/, "\n\n")

      # Remove trailing spaces
      text.gsub!(/[ \t]+$/, '')

      # Remove leading spaces on each line (except for indented code)
      text.gsub!(/^([^\s])/, '\1').gsub!(/^[ \t]+/, '')

      text
    end

    # Обрабатывает переносы строк
    #
    # @param text [String] текст для обработки
    # @param preserve [Boolean] сохранять переносы строк
    # @return [String] обработанный текст
    def handle_line_breaks(text, preserve)
      if preserve
        # Convert single newlines to spaces, preserve double newlines
        text.gsub!(/(?<!\n)\n(?!\n)/, ' ')
      else
        # Convert all newlines to spaces for single line messages
        text.gsub!(/\n+/, ' ')
      end

      # Normalize multiple spaces
      text.gsub!(/ +/, ' ')

      text
    end
  end
end
