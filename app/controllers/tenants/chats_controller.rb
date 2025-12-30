# frozen_string_literal: true

module Tenants
  # Контроллер для просмотра и управления чатами tenant'а
  #
  # Показывает список чатов с пагинацией и сортировкой,
  # историю переписки выбранного чата, а также позволяет
  # менеджерам перехватывать диалоги и отправлять сообщения.
  class ChatsController < ApplicationController
    include ErrorLogger

    PER_PAGE = 20

    # GET /chats
    # GET /chats?sort=created_at
    def index
      @chats = fetch_chats
      # Reload first chat with all messages (fetch_chats only preloads last message for preview)
      @chat = load_chat_with_messages(@chats.first&.id)
    end

    # GET /chats/:id
    def show
      @chats = fetch_chats
      @chat = load_chat_with_messages(params[:id])
    end

    # POST /chats/:id/takeover
    # Перехват диалога менеджером
    def takeover
      @chat = find_chat
      ChatTakeoverService.new(@chat).takeover!(current_user)

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to tenant_chat_path(@chat), notice: t('.success') }
      end
    rescue ChatTakeoverService::AlreadyTakenError => e
      respond_with_error(t('.already_taken'))
    rescue ChatTakeoverService::UnauthorizedError => e
      respond_with_error(t('.unauthorized'))
    end

    # POST /chats/:id/release
    # Возврат диалога боту
    def release
      @chat = find_chat
      ChatTakeoverService.new(@chat).release!(user: current_user)

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to tenant_chat_path(@chat), notice: t('.success') }
      end
    rescue ChatTakeoverService::NotTakenError => e
      respond_with_error(t('.not_taken'))
    rescue ChatTakeoverService::UnauthorizedError => e
      respond_with_error(t('.unauthorized'))
    end

    # POST /chats/:id/send_message
    # Отправка сообщения менеджером
    def send_message
      @chat = find_chat

      return respond_with_error(t('.empty_message')) if params[:text].blank?

      @message = ManagerMessageService.new(@chat).send!(current_user, params[:text])

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to tenant_chat_path(@chat) }
      end
    rescue ManagerMessageService::NotInManagerModeError => e
      respond_with_error(t('.not_in_manager_mode'))
    rescue ManagerMessageService::NotTakenByUserError => e
      respond_with_error(t('.not_taken_by_user'))
    rescue ManagerMessageService::RateLimitExceededError => e
      respond_with_error(t('.rate_limit_exceeded'))
    end

    private

    # Загружает чат со всеми сообщениями (с лимитом для производительности)
    def load_chat_with_messages(chat_id)
      return nil if chat_id.blank?

      chat = current_tenant.chats
                           .with_client_details
                           .includes(:bookings)
                           .find(chat_id)

      # Загружаем сообщения с лимитом для производительности
      # (200 сообщений ≈ 120KB HTML, 2000 DOM nodes)
      # Используем id как tiebreaker при одинаковом created_at
      messages = chat.messages
                     .includes(:tool_calls)
                     .order(created_at: :desc, id: :desc)
                     .limit(ApplicationConfig.max_chat_messages_display)
                     .reverse

      # Перезаписываем кэш ассоциации ограниченным набором сообщений
      chat.association(:messages).target = messages

      chat
    end

    def fetch_chats
      chats = current_tenant.chats
                            .with_client_details
                            .order(sort_column => :desc)
                            .page(params[:page])
                            .per(PER_PAGE)

      # Preload last message for each chat (optimized single query)
      preload_last_messages(chats)

      chats
    end

    def preload_last_messages(chats)
      return if chats.empty?

      # Get last message for each chat in single query using DISTINCT ON
      # Order by id DESC as tiebreaker when created_at is the same
      last_messages = Message
        .where(chat_id: chats.map(&:id))
        .select('DISTINCT ON (chat_id) *')
        .order('chat_id, created_at DESC, id DESC')
        .index_by(&:chat_id)

      # Assign to association cache
      chats.each do |chat|
        chat.association(:messages).target = [ last_messages[chat.id] ].compact
      end
    end

    def sort_column
      %w[last_message_at created_at].include?(params[:sort]) ? params[:sort] : 'last_message_at'
    end

    # Находит чат для takeover/release/send_message actions
    def find_chat
      current_tenant.chats
                    .with_client_details
                    .includes(messages: :tool_calls)
                    .find(params[:id])
    end

    # Отвечает с ошибкой
    def respond_with_error(message)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            'flash',
            partial: 'tenants/shared/flash',
            locals: { message: message, type: :error }
          )
        end
        format.html { redirect_to tenant_chat_path(@chat), alert: message }
      end
    end
  end
end
