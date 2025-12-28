# frozen_string_literal: true

# Конфигурация классификатора тем чатов
#
# @example Использование
#   config = TopicClassifierConfig.new
#   config.model            #=> 'gpt-4o-mini'
#   config.inactivity_hours #=> 24
#
# @see ChatTopicClassifier
# @see ClassifyInactiveChatsJob
class TopicClassifierConfig < Anyway::Config
  config_name :topic_classifier
  env_prefix ''

  attr_config(
    # Включена ли классификация топиков (по умолчанию отключена)
    enabled: false,

    # Модель для классификации (дешёвая)
    model: nil,

    # Часы неактивности до классификации
    inactivity_hours: 24
  )

  coerce_types(
    enabled: :boolean,
    model: :string,
    inactivity_hours: :integer
  )

  # Возвращает модель для классификации
  # Если не задана, использует основную модель приложения
  #
  # @return [String] идентификатор модели
  def model_with_fallback
    model.presence || ApplicationConfig.llm_model
  end

  # Возвращает провайдера для классификации
  # Использует основного провайдера приложения
  #
  # @return [String] провайдер LLM
  def provider
    ApplicationConfig.llm_provider
  end

  class << self
    delegate_missing_to :instance

    private

    def instance
      @instance ||= new
    end
  end
end
