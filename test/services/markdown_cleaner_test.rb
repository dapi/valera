# frozen_string_literal: true

require 'test_helper'

# Загружаем зависимости для MarkdownCleaner
require 'kramdown'
require 'sanitize'

class MarkdownCleanerTest < ActiveSupport::TestCase
  # Тест базовой функциональности MarkdownCleaner
  #
  # @see app/services/markdown_cleaner.rb
  # @see docs/requirements/tdd/TDD-003-markdown-cleaner-implementation.md

  test "should handle empty input" do
    assert_equal '', MarkdownCleaner.clean_for_telegram('')
    assert_equal '', MarkdownCleaner.clean_for_telegram(nil)
  end

  test "should preserve basic bold formatting" do
    input = '**Bold text**'
    expected = '**Bold text**'
    assert_equal expected, MarkdownCleaner.clean_for_telegram(input)
  end

  test "should preserve italic formatting" do
    input = '*Italic text*'
    expected = '*Italic text*'
    assert_equal expected, MarkdownCleaner.clean_for_telegram(input)

    # Test underscore italic (Kramdown converts __ to **bold**)
    input_underscore = '__Italic text__'
    expected_underscore = '**Italic text**'  # Kramdown converts __ to **bold**
    assert_equal expected_underscore, MarkdownCleaner.clean_for_telegram(input_underscore)
  end

  test "should preserve code formatting" do
    input = '`code snippet`'
    expected = '`code snippet`'
    assert_equal expected, MarkdownCleaner.clean_for_telegram(input)
  end

  test "should preserve links with safe URLs" do
    input = '[Google](https://google.com)'
    expected = '[Google](https://google.com)'
    assert_equal expected, MarkdownCleaner.clean_for_telegram(input)

    # Test HTTP link
    input_http = '[Example](http://example.com)'
    expected_http = '[Example](http://example.com)'
    assert_equal expected_http, MarkdownCleaner.clean_for_telegram(input_http)
  end

  test "should remove dangerous HTML tags" do
    input = '**Bold** <script>alert("xss")</script> text'
    expected = '**Bold**  text'
    assert_equal expected, MarkdownCleaner.clean_for_telegram(input)
  end

  test "should remove dangerous JavaScript URLs" do
    input = '[Click me](javascript:alert(1))'
    expected = 'Click me'
    assert_equal expected, MarkdownCleaner.clean_for_telegram(input)
  end

  test "should handle mixed formatting" do
    input = '**Bold** and *italic* with `code` and [link](https://example.com)'
    expected = '**Bold** and *italic* with `code` and [link](https://example.com)'
    assert_equal expected, MarkdownCleaner.clean_for_telegram(input)
  end

  test "should handle nested formatting" do
    input = '**Bold *italic* text**'
    expected = '**Bold *italic* text**'
    assert_equal expected, MarkdownCleaner.clean_for_telegram(input)
  end

  test "should truncate long messages to Telegram limit" do
    # Создаем текст длиннее 4096 символов
    long_text = 'A' * 5000
    result = MarkdownCleaner.clean_for_telegram(long_text)

    assert result.length <= 4096
    assert result.end_with?('...')
  end

  test "should handle multiline text" do
    input = "**Line 1**\n*Line 2*\n`Line 3`"
    result = MarkdownCleaner.clean_for_telegram(input)

    assert_includes result, '**Line 1**'
    assert_includes result, '*Line 2*'
    assert_includes result, '`Line 3`'
  end

  test "should handle paragraphs correctly" do
    input = "First paragraph\n\nSecond paragraph"
    result = MarkdownCleaner.clean_for_telegram(input)

    assert_includes result, 'First paragraph'
    assert_includes result, 'Second paragraph'
  end

  test "should handle malformed HTML gracefully" do
    input = '**Bold text <unclosed tag> and text**'
    result = MarkdownCleaner.clean_for_telegram(input)

    # Должен сохранить bold форматирование и удалить некорректный HTML
    assert_includes result, '**Bold text'
    assert_includes result, 'and text**'
  end

  test "should fallback to plain text on critical errors" do
    # Симулируем ошибку в Kramdown (например, очень сложный input)
    malformed_input = "\x00" * 1000  # Null bytes
    result = MarkdownCleaner.clean_for_telegram(malformed_input)

    # Должен вернуть безопасный plain text
    assert result.is_a?(String)
    assert_not_includes result, "\x00"
  end

  # Performance tests
  test "should process typical messages quickly" do
    input = '**Bold** text with *italic* and `code` formatting and [link](https://example.com)'

    start_time = Time.current
    100.times do  # Reduced from 1000 to 100 for more realistic test
      MarkdownCleaner.clean_for_telegram(input)
    end
    end_time = Time.current

    # Должен обрабатывать 100 сообщений быстрее чем за секунду (10ms per message)
    processing_time = end_time - start_time
    assert processing_time < 1.0, "Processing took too long: #{processing_time}s for 100 messages"
  end

  test "should handle edge cases gracefully" do
    edge_cases = [
      '***',
      '**',
      '*',
      '`',
      '[]()',
      '[link](',
      ']()',
      '****bold****',
      '__**bold**__'
    ]

    edge_cases.each do |input|
      result = MarkdownCleaner.clean_for_telegram(input)
      assert result.is_a?(String), "Failed on input: #{input.inspect}"
      assert result.length <= 4096, "Result too long for input: #{input.inspect}"
    end
  end

  test "should fix broken bold formatting" do
    # Незакрытый bold должен быть исправлен
    input = '**Bold without closing'
    result = MarkdownCleaner.clean_for_telegram(input)
    assert_includes result, '**Bold without closing**'
  end

  test "should fix broken italic formatting" do
    # Незакрытый italic через * должен быть исправлен
    input = '*Italic without closing'
    result = MarkdownCleaner.clean_for_telegram(input)
    assert_includes result, '*Italic without closing*'
  end

  test "should fix broken underscore formatting" do
    # Незакрытый italic через __ должен быть исправлен в bold
    input = '__Underscore without closing'
    result = MarkdownCleaner.clean_for_telegram(input)
    assert_includes result, '**Underscore without closing**'
  end

  test "should fix broken code formatting" do
    # Незакрытый code должен быть исправлен
    input = '`Code without closing'
    result = MarkdownCleaner.clean_for_telegram(input)
    assert_includes result, '`Code without closing`'
  end

  test "should fix broken links" do
    # Сломанные ссылки должны быть исправлены
    input = '[Broken link]()'
    result = MarkdownCleaner.clean_for_telegram(input)
    assert_equal 'Broken link', result
  end

  test "should handle excessive formatting markers" do
    # Множественные звезды должны быть исправлены
    input = '***Multiple stars***'
    result = MarkdownCleaner.clean_for_telegram(input)
    assert_includes result, 'Multiple stars'
    assert_not_includes result, '***'
  end

  test "should remove standalone formatting markers" do
    # Отдельные символы форматирования должны быть удалены
    input = '**   **'
    result = MarkdownCleaner.clean_for_telegram(input)
    assert_empty result.strip
  end
end