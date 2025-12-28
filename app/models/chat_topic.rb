# frozen_string_literal: true

# Тема обращения клиента в чате
#
# Топики используются для классификации диалогов и аналитики.
# Могут быть глобальными (tenant_id = nil) или специфичными для тенанта.
#
# @example Глобальный топик
#   ChatTopic.create!(key: 'booking', label: 'Запись на сервис')
#
# @example Топик тенанта
#   ChatTopic.create!(tenant: tenant, key: 'tire_change', label: 'Замена шин')
#
# @see ChatTopicClassifier
# @see Chat#chat_topic
class ChatTopic < ApplicationRecord
  belongs_to :tenant, optional: true
  has_many :chats, dependent: :nullify

  validates :key, presence: true,
                  format: { with: /\A[a-z][a-z0-9_]*\z/, message: 'только латинские буквы, цифры и подчёркивания' }
  validates :key, uniqueness: { scope: :tenant_id }
  validates :label, presence: true

  scope :active, -> { where(active: true) }
  scope :global, -> { where(tenant_id: nil) }
  scope :for_tenant, ->(tenant) { where(tenant_id: [nil, tenant.id]) }

  # Возвращает топики для использования в классификаторе
  # Приоритет: топики тенанта, если есть, иначе глобальные
  #
  # @param tenant [Tenant] тенант
  # @return [ActiveRecord::Relation<ChatTopic>]
  def self.effective_for(tenant)
    tenant_topics = active.where(tenant: tenant)
    tenant_topics.exists? ? tenant_topics : active.global
  end

  # Находит или создаёт топик "other" для fallback
  #
  # @param tenant [Tenant, nil] тенант
  # @return [ChatTopic]
  def self.fallback_topic(tenant = nil)
    scope = tenant ? where(tenant: tenant) : global
    scope.find_by(key: 'other') || global.find_by(key: 'other')
  end

  def to_s
    label
  end

  def global?
    tenant_id.nil?
  end
end
