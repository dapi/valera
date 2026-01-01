# frozen_string_literal: true

module Tenants
  # Контроллер для просмотра чатов tenant'а
  #
  # Показывает список чатов с пагинацией и сортировкой,
  # историю переписки выбранного чата.
  #
  # Для управления режимом менеджера (takeover/release/messages)
  # используется Tenants::Chats::ManagerController.
  class ChatsController < ApplicationController

    # GET /chats
    # GET /chats?sort=created_at
    # XHR GET /chats?page=2 (AJAX for infinite scroll)
    def index
      @chats = fetch_chats

      # AJAX request for infinite scroll - return only chat list items
      if request.xhr?
        render partial: 'chat_list_items', locals: { chats: @chats, current_chat: nil }
        return
      end

      # Reload first chat with all messages (fetch_chats only preloads last message for preview)
      @chat = load_chat_with_messages(@chats.first&.id)
    end

    # GET /chats/:id
    def show
      @chats = fetch_chats
      @chat = load_chat_with_messages(params[:id])
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
      # Используем reorder чтобы переопределить default scope из acts_as_chat
      # (acts_as_chat добавляет order(created_at: :asc), который иначе объединяется с нашим order)
      messages = chat.messages
                     .includes(:tool_calls)
                     .reorder(created_at: :desc, id: :desc)
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
                            .per(ApplicationConfig.chats_per_page)

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
  end
end
