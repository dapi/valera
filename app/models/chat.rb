class Chat < ApplicationRecord
  include ErrorLogger

  belongs_to :telegram_user
  has_many :bookings, dependent: :destroy

  acts_as_chat

  before_create do
    self.model ||= Model.find_by!(provider: ApplicationConfig.llm_provider, model_id: ApplicationConfig.llm_model)
    # with_tool BookingTool
  end

  after_create do
    with_instructions SystemPromptService.system_prompt
    # with_tool BookingTool
  end

  def reset!
    messages.destroy_all
    with_instructions SystemPromptService.system_prompt
    # with_tool BookingTool
  end

  # Override the default persistence methods как в примере
  private

  def set_tenant_context
    self.context = RubyLLM.context do |config|
      config.openai_api_key = tenant.openai_api_key
    end
  end

  def persist_new_message
    # Create a new message object but don't save it yet
    @message = messages.new(role: :assistant)
  end

  def persist_message_completion(message)
    return unless message

    # Find tool_call database ID if this is a tool result message
    tool_call_db_id = find_tool_call_db_id(message.tool_call_id) if message.tool_call_id

    # Fill in attributes and save once we have content
    @message.assign_attributes(
      role: message.role,
      content: message.content,
      model: Model.find_by(model_id: message.model_id),
      input_tokens: message.input_tokens,
      output_tokens: message.output_tokens
    )

    # Set tool_call_id for tool result messages
    @message.tool_call_id = tool_call_db_id if tool_call_db_id

    @message.save!

    # Handle tool calls if present
    persist_tool_calls(message.tool_calls) if message.tool_calls.present?
  end

  def persist_tool_calls(tool_calls)
    tool_calls.each_value do |tool_call|
      attributes = tool_call.to_h
      attributes[:tool_call_id] = attributes.delete(:id)
      @message.tool_calls.create!(**attributes)

      # Обрабатываем tool calls если это booking_creator
      handle_booking_creator_persisted(tool_call) if tool_call.name == 'booking_creator'
    end
  rescue => e
    log_error(e, {
                model: self.class.name,
                method: 'persist_tool_calls',
                chat_id: id,
                tool_call_data: tool_call&.to_h
              })
    raise e
  end

  def handle_booking_creator_persisted(tool_call)
      # Извлекаем параметры из tool call
      parameters = JSON.parse(tool_call.arguments || '{}')

      # Вызываем BookingCreatorTool с нужным контекстом
      result = BookingCreatorTool.call(
        parameters: parameters,
        context: {
          telegram_user: telegram_user,
          chat: self
        }
      )

      Rails.logger.info "Booking creator tool executed successfully: #{result[:booking_id]}"
    rescue => e
      log_error(e, {
                  tool: 'booking_creator',
                  tool_call_id: tool_call.id,
                  telegram_user_id: telegram_user&.id,
                  chat_id: id,
                  parameters: parameters
                })
  end

  def find_tool_call_db_id(api_tool_call_id)
    # Find ToolCall record by API tool_call_id (e.g., "call_00_...")
    # and return its database ID
    tool_call_record = ToolCall.find_by(tool_call_id: api_tool_call_id)
    tool_call_record&.id
  end
end
