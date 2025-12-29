# frozen_string_literal: true

# Global Chat Topics seeder
# Creates default topics for dialog classification (tenant_id: nil = global)

Rails.logger.info '[Seeds] Creating global chat topics...'

DEFAULT_CHAT_TOPICS = [
  { key: 'service_booking', label: 'Запись на обслуживание' },
  { key: 'price_inquiry', label: 'Запрос цены/стоимости' },
  { key: 'diagnostics', label: 'Диагностика/проверка' },
  { key: 'repair', label: 'Ремонт' },
  { key: 'parts', label: 'Запчасти/расходники' },
  { key: 'schedule', label: 'График работы/адрес' },
  { key: 'feedback', label: 'Отзыв/жалоба' },
  { key: 'general_question', label: 'Общий вопрос' },
  { key: 'other', label: 'Другое' }
].freeze

DEFAULT_CHAT_TOPICS.each do |topic_data|
  ChatTopic.find_or_create_by!(key: topic_data[:key], tenant_id: nil) do |topic|
    topic.label = topic_data[:label]
    topic.active = true
  end
end

Rails.logger.info "[Seeds] Created #{DEFAULT_CHAT_TOPICS.size} global chat topics"
