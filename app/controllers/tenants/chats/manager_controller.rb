# frozen_string_literal: true

module Tenants
  module Chats
    # Контроллер для управления режимом менеджера в чате
    #
    # Использует Turbo Streams для обновления UI без перезагрузки страницы.
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

      before_action :ensure_manager_takeover_enabled
      before_action :set_chat

      # POST /chats/:chat_id/manager/takeover
      #
      # Менеджер берёт контроль над чатом.
      # После takeover бот перестаёт отвечать, все сообщения
      # от клиента будут видны только в dashboard.
      def takeover
        result = Manager::TakeoverService.call(
          chat: @chat,
          user: current_user,
          timeout_minutes: params[:timeout_minutes].presence&.to_i,
          notify_client: notify_client_param
        )

        if result.success?
          @chat.reload
          # renders takeover.turbo_stream.slim
        else
          render_turbo_stream_error(result.error)
        end
      end

      # POST /chats/:chat_id/manager/messages
      #
      # Отправляет сообщение от имени менеджера клиенту в Telegram.
      # Требует чтобы чат был в режиме менеджера и
      # текущий пользователь был активным менеджером.
      #
      # @param content [String] текст сообщения (обязательный)
      def create_message
        content = message_params[:content]

        if content.blank?
          return render_turbo_stream_error(t('.content_required'))
        end

        result = Manager::MessageService.call(
          chat: @chat,
          user: current_user,
          content:
        )

        if result.success?
          @message = result.message
          # renders create_message.turbo_stream.slim
        else
          render_turbo_stream_error(result.error)
        end
      end

      # POST /chats/:chat_id/manager/release
      #
      # Возвращает чат боту. После release бот снова
      # начинает отвечать на сообщения клиента.
      def release
        result = Manager::ReleaseService.call(
          chat: @chat,
          user: current_user,
          notify_client: notify_client_param
        )

        if result.success?
          @chat.reload
          # renders release.turbo_stream.slim
        else
          render_turbo_stream_error(result.error)
        end
      end

      private

      def set_chat
        @chat = current_tenant.chats.find(params[:chat_id])
      rescue ActiveRecord::RecordNotFound => e
        log_error(e, error_context)
        render_turbo_stream_error(t('.chat_not_found'), status: :not_found)
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

      def error_context
        {
          controller: self.class.name,
          action: action_name,
          chat_id: params[:chat_id],
          user_id: current_user&.id,
          tenant_id: current_tenant&.id
        }
      end

      # Проверяет что функция manager takeover включена в конфигурации
      def ensure_manager_takeover_enabled
        return if ApplicationConfig.manager_takeover_enabled

        render_turbo_stream_error(t('.feature_disabled'), status: :not_found)
      end

      # Рендерит ошибку через Turbo Stream в flash контейнер
      def render_turbo_stream_error(message, status: :unprocessable_entity)
        render turbo_stream: turbo_stream.update(
          'flash',
          partial: 'tenants/shared/flash',
          locals: { message:, type: :error }
        ), status:
      end
    end
  end
end
