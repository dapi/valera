# frozen_string_literal: true

# Сервис для отправки приветственных сообщений новым пользователям
#
# Управляет отправкой персонализированных приветственных сообщений
# пользователям, которые впервые взаимодействуют с ботом.
#
# @example Использование сервиса
#   service = WelcomeService.new
#   service.send_welcome_message(user, controller)
#
# @see ApplicationConfig для шаблона приветственного сообщения
# @see TelegramUser для работы с данными пользователя
# @author Danil Pismenny
# @since 0.1.0
class WelcomeService
  include ErrorLogger
  include DevelopmentWarning

  # Отправляет приветственное сообщение пользователю
  #
  # Использует шаблон из конфигурации и подставляет в него имя пользователя.
  # Отправка происходит через контроллер с помощью respond_with.
  # В development режиме дополнительно отправляет предупреждение о тестовом статусе.
  #
  # @param telegram_user [TelegramUser] пользователь для приветствия
  # @param controller [Telegram::WebhookController] контроллер для отправки
  # @return [void] отправляет сообщение через Telegram API
  # @raise [StandardError] при ошибке отправки сообщения
  # @example
  #   service = WelcomeService.new
  #   service.send_welcome_message(user, controller)
  #   #=> Пользователь получит приветственное сообщение + предупреждение в development
  def send_welcome_message(telegram_user, controller)
    message = interpolate_template(ApplicationConfig.welcome_message_template, telegram_user)

    # Отправка приветственного сообщения
    controller.respond_with :message, text: message

    # Отправка предупреждения о development режиме (отдельным сообщением)
    send_development_warning(controller)
  end

  private

  # Выполняет интерполяцию шаблона с данными пользователя
  #
  # @param template [String] шаблон сообщения с плейсхолдерами
  # @param telegram_user [TelegramUser] пользователь для подстановки данных
  # @return [String] отформатированное сообщение с подставленным именем
  # @example
  #   interpolate_template("Привет, #{name}!", user)
  #   #=> "Привет, Иван!"
  # @api private
  def interpolate_template(template, telegram_user)
    # Интерполяция #{name} -> telegram_user.name
    template.gsub(/\#{name\}/, telegram_user.name)
  end
end
