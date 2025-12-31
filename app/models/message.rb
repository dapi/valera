# frozen_string_literal: true

# Represents a single message within a chat conversation
#
# @attr [String] role роль отправителя (user, assistant, tool, system)
# @attr [String] content содержимое сообщения
# @attr [Integer] sender_type тип отправителя для assistant сообщений
# @attr [Integer] sender_id ID пользователя, если отправлено менеджером
class Message < ApplicationRecord
  ROLES = %w[user assistant manager system tool].freeze

  acts_as_message touch_chat: :last_message_at
  has_many_attached :attachments

  belongs_to :sender, class_name: 'User', optional: true

  # Тип отправителя для различения AI и менеджера в истории чата
  # ai: сообщение от AI-бота (по умолчанию)
  # manager: сообщение от менеджера в режиме takeover
  # client: сообщение от клиента (для аналитики)
  # system: системное уведомление (переключение на менеджера и т.д.)
  enum :sender_type, { ai: 0, manager: 1, client: 2, system: 3 }, default: :ai

  validates :sender, presence: true, if: :manager?

  # Broadcast new messages to dashboard for real-time updates
  after_create_commit :broadcast_to_dashboard

  scope :from_manager, -> { where(role: 'manager') }
  scope :from_bot, -> { where(role: 'assistant') }
  scope :from_client, -> { where(role: 'user') }

  # Возвращает true, если сообщение отправлено менеджером
  def from_manager?
    manager?
  end

  # Возвращает true, если сообщение является системным уведомлением
  def system_notification?
    system?
  end

  private

  def broadcast_to_dashboard
    broadcast_append_to(
      chat,
      target: 'chat-messages',
      partial: 'tenants/chats/message',
      locals: { message: self }
    )
  end
end
