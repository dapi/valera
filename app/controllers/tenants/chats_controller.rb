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
      @chat = current_tenant.chats.includes(:client, messages: :tool_calls).find(params[:id])
    end

    private

    def fetch_chats
      current_tenant.chats
                    .includes(:client)
                    .order(sort_column => :desc)
                    .page(params[:page])
                    .per(PER_PAGE)
    end

    def sort_column
      %w[last_message_at created_at].include?(params[:sort]) ? params[:sort] : 'last_message_at'
    end
  end
end
