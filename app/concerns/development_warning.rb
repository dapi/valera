# frozen_string_literal: true

# Модуль для отображения предупреждений в development режиме
#
# Предоставляет функциональность для добавления предупреждений
# пользователям о том, что бот находится в разработке.
#
# @example Использование в классе
#   class MyService
#     include DevelopmentWarning
#
#     def send_message
#       send_welcome_message
#       send_development_warning if development_warnings_enabled?
#     end
#   end
#
# @author Danil Pismenny
# @since 0.1.0
module DevelopmentWarning
  # Отправляет предупреждение о разработке
  #
  # Проверяет конфигурацию и отправляет предупреждение через контроллер.
  # Предупреждение отправляется отдельным сообщением с Markdown форматированием.
  #
  # @param controller [Telegram::Bot::UpdatesController] контроллер для отправки
  # @return [void] отправляет сообщение пользователю
  # @raise [StandardError] при ошибке отправки сообщения
  # @note Отправляется отдельным сообщением, не в составе основного контента
  # @example
  #   send_development_warning(controller)
  #   #=> Пользователь получит отдельное сообщение с предупреждением
  def send_development_warning(controller)
    return unless development_warnings_enabled?

    controller.respond_with :message, text: development_warning_text, parse_mode: 'Markdown'
  end

  def development_warnings_enabled?
    ApplicationConfig.development_warning
  end

  # Возвращает текст предупреждения о разработке
  #
  # Проверяет конфигурацию и возвращает подробный текст предупреждения
  # если включен development режим и предупреждения активированы.
  #
  # @return [String] текст предупреждения или пустая строка
  # @example
  #   development_warning_text
  #   #=> "⚠️ **ВНИМАНИЕ**: Это демонстрационная версия бота!..."
  def development_warning_text
    I18n.t('development_warning.welcome')
  end
end
