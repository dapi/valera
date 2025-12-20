# frozen_string_literal: true

# Сервис для отправки приветственных сообщений новым пользователям
#
# Управляет отправкой персонализированных приветственных сообщений
# пользователям, которые впервые взаимодействуют с ботом.
#
# В multi-tenant режиме использует Current.tenant.welcome_message,
# с fallback на глобальный шаблон из ApplicationConfig.
#
# @example Использование сервиса
#   Current.tenant = tenant
#   service = WelcomeService.new
#   service.send_welcome_message(user, controller)
#
# @see ApplicationConfig для шаблона приветственного сообщения
# @see TelegramUser для работы с данными пользователя
# @see Current для multi-tenancy контекста
# @author Danil Pismenny
# @since 0.1.0
class WelcomeService
  include ErrorLogger
  include DevelopmentWarning

  # Отправляет приветственное сообщение пользователю
  #
  # Использует шаблон из текущего тенанта или конфигурации и подставляет в него имя пользователя.
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
    message = interpolate_template(welcome_message_template, telegram_user)

    # Измерение времени доставки приветствия
    start_time = Time.current

    # Отправка приветственного сообщения
    controller.respond_with :message, text: message

    delivery_time_ms = ((Time.current - start_time) * 1000).round(2)

    # Трекинг события GREETING_SENT
    track_greeting_sent(telegram_user, delivery_time_ms)

    # Отправка предупреждения о development режиме (отдельным сообщением)
    send_development_warning(controller)
  rescue StandardError => e
    log_error(e, { user_id: telegram_user&.id, context: 'send_welcome_message' })
    raise
  end

  private

  # Возвращает шаблон приветственного сообщения
  #
  # Приоритет: Current.tenant.welcome_message -> ApplicationConfig.welcome_message_template
  #
  # @return [String] шаблон приветственного сообщения
  # @api private
  def welcome_message_template
    tenant_welcome = Current.tenant&.welcome_message
    return tenant_welcome if tenant_welcome.present?

    ApplicationConfig.welcome_message_template
  end

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

  # Отправляет событие GREETING_SENT в аналитику
  #
  # @param telegram_user [TelegramUser] пользователь получивший приветствие
  # @param delivery_time_ms [Float] время доставки в миллисекундах
  # @return [void]
  # @api private
  def track_greeting_sent(telegram_user, delivery_time_ms)
    AnalyticsService.track(
      AnalyticsService::Events::GREETING_SENT,
      chat_id: telegram_user.chat_id,
      properties: {
        user_id: telegram_user.id,
        user_type: determine_user_type(telegram_user),
        delivery_time_ms: delivery_time_ms
      }
    )
  end

  # Определяет тип пользователя (new или returning)
  #
  # @param telegram_user [TelegramUser] пользователь для анализа
  # @return [String] 'new' для новых пользователей, 'returning' для возвращающихся
  # @note Пользователь считается новым если создан менее 24 часов назад
  # @api private
  def determine_user_type(telegram_user)
    # Пользователь считается новым если создан менее 24 часов назад
    time_since_creation = Time.current - telegram_user.created_at

    if time_since_creation < 24.hours
      'new'
    else
      'returning'
    end
  end
end
