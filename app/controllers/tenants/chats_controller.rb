# frozen_string_literal: true

module Tenants
  # Контроллер для просмотра чатов tenant'а
  #
  # Показывает список чатов с пагинацией и сортировкой,
  # а также историю переписки выбранного чата.
  class ChatsController < ApplicationController
    PER_PAGE = 20

    # GET /chats
    # GET /chats?sort=created_at
    def index
      @chats = fetch_chats
      @chat = @chats.first
    end

    # GET /chats/:id
    def show
      @chats = fetch_chats
      @chat = current_tenant.chats
                            .includes(client: :telegram_user)
                            .includes(:bookings)
                            .includes(messages: :tool_calls)
                            .find(params[:id])
    end

    private

    def fetch_chats
      chats = current_tenant.chats
                            .includes(client: :telegram_user)
                            .order(sort_column => :desc)
                            .page(params[:page])
                            .per(PER_PAGE)

      # Preload last message for each chat (optimized single query)
      preload_last_messages(chats)

      chats
    end

    def preload_last_messages(chats)
      return if chats.empty?

      # Get last message for each chat in single query using window function
      last_messages = Message
        .where(chat_id: chats.map(&:id))
        .select('DISTINCT ON (chat_id) *')
        .order('chat_id, created_at DESC')
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
