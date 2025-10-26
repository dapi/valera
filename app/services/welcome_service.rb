# frozen_string_literal: true

# Service for sending welcome messages to new Telegram users
class WelcomeService
  include ErrorLogger
  def send_welcome_message(telegram_user, controller)
    template = ApplicationConfig.welcome_message_template
    message = interpolate_template(template, telegram_user)

    # Отправка через respond_with из контроллера
    controller.respond_with :message, text: message

    # Логирование отправки приветствия
    Rails.logger.info "Welcome message sent to telegram_user_id: #{telegram_user.id}, name: #{telegram_user.name}"
  rescue => e
    log_error(e, {
      service: self.class.name,
      method: 'send_welcome_message',
      telegram_user_class: telegram_user.class.name,
      telegram_user_id: telegram_user.try(:id),
      telegram_user_inspect: telegram_user.inspect[0..200] # ограничим длину
    })
    raise
  end

  private

  def interpolate_template(template, telegram_user)
    # Интерполяция #{name} -> telegram_user.name
    template.gsub(/\#{name\}/, telegram_user.name)
  rescue => e
    log_error(e, {
      service: self.class.name,
      method: 'interpolate_template',
      telegram_user_class: telegram_user.class.name,
      template_length: template&.length,
      telegram_user_methods: telegram_user.methods.map(&:to_s).select { |m| m.match?(/name|first|last/) }.sort
    })
    # Возвращаем шаблон без интерполяции в случае ошибки
    template || "Добро пожаловать!"
  end
end