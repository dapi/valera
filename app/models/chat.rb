class Chat < ApplicationRecord
  acts_as_chat
  belongs_to :telegram_user
  has_many :bookings, dependent: :destroy

  # Используем дефолтную модель из ruby_llm
  def model
    Model.find_by(provider: ApplicationConfig.llm_provider, name: ApplicationConfig.llm_model)
  end

  # Регистрируем tools для LLM
  def self.booking_tools
    [
      {
        name: 'booking_creator',
        description: "Создает запись клиента на осмотр в автосервис через естественный диалог",
        input_schema: {
          type: "object",
          properties: {
            customer_name: {
              type: "string",
              description: "Полное имя клиента"
            },
            customer_phone: {
              type: "string",
              description: "Телефон клиента в формате +7(XXX)XXX-XX-XX"
            },
            car_info: {
              type: "object",
              description: "Информация об автомобиле клиента",
              properties: {
                brand: { type: "string", description: "Марка автомобиля" },
                model: { type: "string", description: "Модель автомобиля" },
                year: { type: "integer", description: "Год выпуска автомобиля" },
                car_class: { type: "integer", description: "Класс автомобиля (1/2/3)" }
              },
              required: ["brand", "model", "year"]
            },
            preferred_date: {
              type: "string",
              description: "Предпочтительная дата (LLM определяет из контекста диалога)"
            },
            preferred_time: {
              type: "string",
              description: "Предпочтительное время (может быть точным '10:00' или примерным 'утром', LLM определяет из диалога)"
            }
          },
          required: ["customer_name", "customer_phone", "car_info"]
        }
      }
    ]
  end

  # Override to_llm method для автоматического добавления tools
  def to_llm
    model_record = model_association
    @chat ||= (context || RubyLLM).chat(
      model: model_record.model_id,
      provider: model_record.provider.to_sym
    )
    @chat.reset_messages!

    messages_association.each do |msg|
      @chat.add_message(msg.to_llm)
    end

    # Добавляем booking tools и обработчик
    @chat.with_tools(self.class.booking_tools)
    setup_tool_handlers

    setup_persistence_callbacks
  end

  private

  def setup_tool_handlers
    @chat.on_tool_call do |tool_call|
      case tool_call.name
      when 'booking_creator'
        handle_booking_creator(tool_call)
      else
        Rails.logger.warn "Unknown tool called: #{tool_call.name}"
      end
    end
  end

  def handle_booking_creator(tool_call)
    begin
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

      # Возвращаем результат в LLM
      tool_result = {
        tool_call_id: tool_call.id,
        result: result[:message]
      }

      @chat.add_message(
        role: :tool,
        content: tool_result[:result],
        tool_call_id: tool_call.id
      )

      Rails.logger.info "Booking creator tool executed successfully: #{result[:booking_id]}"
    rescue => e
      Rails.logger.error "Error executing booking creator tool: #{e.message}"
      Bugsnag.notify(e)

      # Возвращаем ошибку в LLM
      @chat.add_message(
        role: :tool,
        content: "Ошибка при создании записи: #{e.message}",
        tool_call_id: tool_call.id
      )
    end
  end
end
