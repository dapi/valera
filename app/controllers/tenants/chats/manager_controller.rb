# frozen_string_literal: true

module Tenants
  module Chats
    # REST API контроллер для управления режимом менеджера в чате
    #
    # Предоставляет endpoints для:
    # - Перехвата чата менеджером (takeover)
    # - Отправки сообщений от менеджера
    # - Возврата чата боту (release)
    #
    # Все endpoints требуют авторизации (owner или member tenant'а).
    #
    # @example Перехват чата
    #   POST /chats/:chat_id/manager/takeover
    #
    # @example Отправка сообщения
    #   POST /chats/:chat_id/manager/messages
    #   { message: { content: "Текст сообщения" } }
    #
    # @example Возврат боту
    #   POST /chats/:chat_id/manager/release
    #
    # @since 0.38.0
    class ManagerController < Tenants::ApplicationController
      include ErrorLogger

      before_action :set_chat

      # Фатальные инфраструктурные ошибки — пробрасываем наверх (согласно CLAUDE.md)
      FATAL_ERRORS = [
        ActiveRecord::ConnectionNotEstablished,
        ActiveRecord::QueryCanceled
      ].freeze

      # Fallback для непредвиденных ошибок — возвращаем JSON вместо HTML
      # Фатальные DB ошибки пробрасываются для 500 + Bugsnag
      rescue_from StandardError do |error|
        raise error if FATAL_ERRORS.any? { |klass| error.is_a?(klass) }
        raise error if defined?(PG::ConnectionBad) && error.is_a?(PG::ConnectionBad)

        log_error(error, error_context)
        render json: { success: false, error: 'Internal server error' }, status: :internal_server_error
      end

      rescue_from ActiveRecord::RecordNotFound do |error|
        log_error(error, error_context)
        render json: { success: false, error: 'Chat not found' }, status: :not_found
      end

      rescue_from ActionController::ParameterMissing do |error|
        log_error(error, error_context)
        render json: { success: false, error: error.message }, status: :bad_request
      end

      # POST /chats/:chat_id/manager/takeover
      #
      # Менеджер берёт контроль над чатом.
      # После takeover бот перестаёт отвечать, все сообщения
      # от клиента будут видны только в dashboard.
      #
      # @return [JSON] статус операции и данные чата
      def takeover
        result = Manager::TakeoverService.call(
          chat: @chat,
          user: current_user,
          timeout_minutes: params[:timeout_minutes]&.to_i,
          notify_client: notify_client_param
        )

        if result.success?
          render json: {
            success: true,
            chat: chat_json(result.chat),
            active_until: result.active_until,
            notification_sent: result.notification_sent
          }
        else
          render json: { success: false, error: result.error }, status: :unprocessable_entity
        end
      end

      # POST /chats/:chat_id/manager/messages
      #
      # Отправляет сообщение от имени менеджера клиенту в Telegram.
      # Требует чтобы чат был в режиме менеджера и
      # текущий пользователь был активным менеджером.
      #
      # @param content [String] текст сообщения (обязательный)
      # @return [JSON] статус операции и данные сообщения
      def create_message
        result = Manager::MessageService.call(
          chat: @chat,
          user: current_user,
          content: message_params[:content]
        )

        if result.success?
          render json: {
            success: true,
            message: message_json(result.message),
            telegram_sent: result.telegram_sent
          }, status: :created
        else
          render json: { success: false, error: result.error }, status: :unprocessable_entity
        end
      end

      # POST /chats/:chat_id/manager/release
      #
      # Возвращает чат боту. После release бот снова
      # начинает отвечать на сообщения клиента.
      #
      # @return [JSON] статус операции
      def release
        result = Manager::ReleaseService.call(
          chat: @chat,
          user: current_user,
          notify_client: notify_client_param
        )

        if result.success?
          render json: {
            success: true,
            chat: chat_json(result.chat),
            notification_sent: result.notification_sent
          }
        else
          render json: { success: false, error: result.error }, status: :unprocessable_entity
        end
      end

      private

      def set_chat
        @chat = current_tenant.chats.find(params[:chat_id])
      end

      # Парсит параметр notify_client как boolean
      # По умолчанию true, если параметр не передан, nil, или нераспознанное значение
      def notify_client_param
        value = params[:notify_client]
        return true if value.nil?

        result = ActiveModel::Type::Boolean.new.cast(value)
        result.nil? ? true : result
      end

      def message_params
        params.require(:message).permit(:content)
      end

      def chat_json(chat)
        {
          id: chat.id,
          manager_active: chat.manager_active?,
          manager_user_id: chat.manager_user_id,
          manager_active_at: chat.manager_active_at,
          manager_active_until: chat.manager_active_until
        }
      end

      def message_json(message)
        {
          id: message.id,
          role: message.role,
          content: message.content,
          created_at: message.created_at
        }
      end

      def error_context
        {
          controller: self.class.name,
          action: action_name,
          chat_id: params[:chat_id],
          user_id: current_user&.id,
          tenant_id: current_tenant&.id
        }
      end
    end
  end
end
