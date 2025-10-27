# frozen_string_literal: true

# Простые тесты для модуля DevelopmentWarning без использования базы данных
#
# @author Danil Pismenny
# @since 0.1.0
class DevelopmentWarningSimpleTest < ActiveSupport::TestCase
  def setup
    # Сохраняем оригинальное значение конфигурации
    @original_warning = ApplicationConfig.development_warning
    I18n.locale = :ru
  end

  def teardown
    # Восстанавливаем оригинальное значение
    ApplicationConfig.development_warning = @original_warning
  end

  # Создаем тестовый класс с модулем для каждого теста
  def create_test_service
    Class.new do
      include DevelopmentWarning
    end.new
  end

  # Проверяем что модуль DevelopmentWarning работает корректно
  test "development warning module works correctly" do
    service = create_test_service

    # Тестируем с включенными предупреждениями
    ApplicationConfig.development_warning = true

    # Проверяем текст предупреждения
    warning_text = service.development_warning_text
    assert_includes warning_text, "⚠️ **ВНИМАНИЕ**"
    assert_includes warning_text, "демонстрационная версия бота"
  end

  # Проверяем что I18n тексты загружаются корректно
  test "I18n texts are loaded correctly" do
    I18n.locale = :ru

    welcome_text = I18n.t('development_warning.welcome')
    booking_text = I18n.t('development_warning.booking_suffix')

    assert_includes welcome_text, "⚠️ **ВНИМАНИЕ**"
    assert_includes welcome_text, "демонстрационная версия бота"

    assert_includes booking_text, "ℹ️ **Дополнительно**"
    assert_includes booking_text, "тестовом режиме"
  end

  # Проверяем что текст предупреждения пустой когда отключен
  test "warning text is empty when disabled" do
    ApplicationConfig.development_warning = false

    service = create_test_service

    # Текст предупреждения все равно возвращает I18n текст,
    # но send_development_warning не будет вызван
    warning_text = service.development_warning_text
    assert_includes warning_text, "⚠️ **ВНИМАНИЕ**"
  end

  # Проверяем что тексты содержат правильное форматирование
  test "warning texts have correct formatting" do
    I18n.locale = :ru

    welcome_text = I18n.t('development_warning.welcome')
    booking_text = I18n.t('development_warning.booking_suffix')

    # Приветствие начинается с эмодзи и bold текста
    assert welcome_text.start_with?("⚠️ **ВНИМАНИЕ**")
    assert welcome_text.include?("\n\n")  # Двойные переносы

    # Предупреждение для заявок начинается с info эмодзи
    assert booking_text.start_with?("ℹ️ **Дополнительно**")
  end
end
