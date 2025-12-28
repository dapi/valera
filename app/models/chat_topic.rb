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
  # Ключ fallback топика для неклассифицированных чатов
  FALLBACK_KEY = 'other'

  belongs_to :tenant, optional: true
  has_many :chats, dependent: :nullify

  # Ключ нельзя менять после создания - это сломает LLM классификацию
  attr_readonly :key

  validates :key, presence: true,
                  length: { maximum: 50 },
                  format: { with: /\A[a-z][a-z0-9_]*\z/, message: 'только латинские буквы, цифры и подчёркивания' }
  validates :key, uniqueness: { scope: :tenant_id }
  validates :label, presence: true, length: { maximum: 100 }

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

  # Находит топик "other" для fallback при неудачной классификации
  #
  # @param tenant [Tenant, nil] тенант
  # @return [ChatTopic, nil] топик или nil если не найден
  def self.fallback_topic(tenant = nil)
    scope = tenant ? where(tenant: tenant) : global
    result = scope.find_by(key: FALLBACK_KEY) || global.find_by(key: FALLBACK_KEY)

    if result.nil?
      Rails.logger.error "[ChatTopic] CRITICAL: Fallback topic '#{FALLBACK_KEY}' not found! Check seeds/migrations."
    end

    result
  end

  def to_s
    label
  end

  def global?
    tenant_id.nil?
  end
end
