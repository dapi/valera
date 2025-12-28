# frozen_string_literal: true

# Классификатор тем чатов с использованием LLM
#
# Анализирует user-сообщения диалога и определяет основную тему обращения.
# Использует дешёвую LLM модель для экономии.
#
# @example Классификация чата
#   classifier = ChatTopicClassifier.new(chat)
#   classifier.classify
#   chat.chat_topic #=> #<ChatTopic key: "booking", label: "Запись на сервис">
#
# @see ChatTopic
# @see TopicClassifierConfig
# @see ClassifyChatTopicJob
class ChatTopicClassifier
  include ErrorLogger

  # @param chat [Chat] чат для классификации
  def initialize(chat)
    @chat = chat
    @tenant = chat.tenant
    @config = TopicClassifierConfig.new
  end

  # Классифицирует чат и сохраняет результат
  #
  # @return [ChatTopic, nil] присвоенный топик или nil если классификация не удалась
  def classify
    return @chat.chat_topic if @chat.chat_topic.present?

    user_messages = fetch_user_messages
    return nil if user_messages.empty?

    topic_key = call_llm(user_messages)
    topic = find_or_fallback_topic(topic_key)

    @chat.update!(chat_topic: topic, topic_classified_at: Time.current)
    topic
  rescue StandardError => e
    log_error(e, context: {
      service: self.class.name,
      chat_id: @chat.id,
      tenant_id: @tenant.id
    })
    nil
  end

  private

  attr_reader :chat, :tenant, :config

  # Получает user-сообщения из чата
  #
  # @return [Array<String>] содержимое сообщений
  def fetch_user_messages
    @chat.messages
      .where(role: 'user')
      .order(:created_at)
      .pluck(:content)
      .compact
  end

  # Вызывает LLM для классификации
  #
  # @param messages [Array<String>] сообщения пользователя
  # @return [String] ключ топика
  def call_llm(messages)
    dialog_content = messages.join("\n---\n")

    llm_chat = RubyLLM.chat(model: config.model_with_fallback)
    response = llm_chat.ask(build_prompt(dialog_content))

    extract_topic_key(response.content)
  end

  # Формирует промпт для LLM
  #
  # @param dialog_content [String] содержимое диалога
  # @return [String] промпт
  def build_prompt(dialog_content)
    topics = ChatTopic.effective_for(@tenant).order(:label)
    topics_description = topics.map { |t| "#{t.key} — #{t.label}" }.join("\n")

    <<~PROMPT
      Определи основную тему обращения клиента в автосервис.

      Возможные темы:
      #{topics_description}

      Ответь ОДНИМ словом (key темы) из списка выше. Без пояснений.

      Диалог клиента:
      #{dialog_content}
    PROMPT
  end

  # Извлекает ключ топика из ответа LLM
  #
  # @param response [String] ответ LLM
  # @return [String] нормализованный ключ
  def extract_topic_key(response)
    response.to_s.strip.downcase.gsub(/[^a-z0-9_]/, '')
  end

  # Находит топик по ключу или возвращает fallback
  #
  # @param topic_key [String] ключ топика
  # @return [ChatTopic] топик
  def find_or_fallback_topic(topic_key)
    topics = ChatTopic.effective_for(@tenant)
    topics.find_by(key: topic_key) || ChatTopic.fallback_topic(@tenant)
  end
end
