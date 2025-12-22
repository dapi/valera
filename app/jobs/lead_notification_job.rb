# frozen_string_literal: true

# Фоновая задача для отправки уведомлений о новых лидах
#
# Асинхронно отправляет данные нового лида в административный чат
# платформы через Platform Bot.
#
# Использует ApplicationConfig.platform_admin_chat_id и Telegram.bot
# для отправки через Platform Bot.
#
# @example Использование задачи
#   LeadNotificationJob.perform_later(lead_id)
#   #=> Уведомление будет отправлено асинхронно
#
# @see Lead для модели лида
# @see ApplicationConfig для настроек platform_admin_chat_id
# @author Danil Pismenny
# @since 0.3.0
class LeadNotificationJob < ApplicationJob
  include ErrorLogger

  queue_as :default

  # Выполняет отправку уведомления о новом лиде
  #
  # @param lead_id [Integer] ID созданного лида
  # @return [void] отправляет сообщение в административный чат платформы
  # @raise [StandardError] при ошибке отправки (с retry логикой)
  def perform(lead_id)
    lead = Lead.find_by(id: lead_id)
    return unless lead

    chat_id = ApplicationConfig.platform_admin_chat_id
    return if chat_id.blank?

    Telegram.bot.send_message(
      chat_id: chat_id,
      text: build_message(lead),
      parse_mode: 'HTML'
    )
  rescue StandardError => e
    log_error(e, job: self.class.name, lead_id: lead_id)
    raise e
  end

  private

  def build_message(lead)
    parts = []
    parts << "🆕 <b>Новый лид!</b>"
    parts << ""
    parts << "👤 #{lead.name}"
    parts << "📞 #{lead.phone}"
    parts << "🏢 #{lead.company_name}" if lead.company_name.present?
    parts << "📍 #{lead.city}" if lead.city.present?
    parts << ""

    if lead.utm_source.present? || lead.utm_medium.present? || lead.utm_campaign.present?
      source_parts = [lead.utm_source, lead.utm_medium, lead.utm_campaign].compact.join(' / ')
      parts << "📊 Источник: #{source_parts}"
    end

    parts << "🔗 #{admin_lead_url(lead)}"

    parts.join("\n")
  end

  def admin_lead_url(lead)
    host = ApplicationConfig.admin_host_with_default
    protocol = ApplicationConfig.protocol
    port = ApplicationConfig.port

    url = "#{protocol}://#{host}"
    unless (port.to_s == '80' && protocol == 'http') || (port.to_s == '443' && protocol == 'https')
      url += ":#{port}"
    end
    url + "/leads/#{lead.id}"
  end
end
