# frozen_string_literal: true

# Service for sending welcome messages to new Telegram users
class WelcomeService
  def send_welcome_message(telegram_user, controller)
    template = ApplicationConfig.welcome_message_template
    message = interpolate_template(template, telegram_user)

    # Отправка через respond_with из контроллера
    controller.respond_with :message, text: message

    # Логирование отправки приветствия
    Rails.logger.info "Welcome message sent to telegram_user_id: #{telegram_user.id}, name: #{telegram_user.name}"
  end

  private

  def interpolate_template(template, telegram_user)
    # Интерполяция #{name} -> telegram_user.name
    template.gsub(/\#{name\}/, telegram_user.name)
  end
end