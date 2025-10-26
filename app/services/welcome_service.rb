# frozen_string_literal: true

# Service for sending welcome messages to new Telegram users
class WelcomeService
  include ErrorLogger
  def send_welcome_message(telegram_user, controller)
    message = interpolate_template(ApplicationConfig.welcome_message_template, telegram_user)

    # Отправка через respond_with из контроллера
    controller.respond_with :message, text: message
  end

  private

  def interpolate_template(template, telegram_user)
    # Интерполяция #{name} -> telegram_user.name
    template.gsub(/\#{name\}/, telegram_user.name)
  end
end
