# frozen_string_literal: true

module Tenants
  # Контроллер для просмотра клиентов tenant'а
  #
  # Показывает список клиентов с пагинацией и поиском,
  # а также детальную информацию о клиенте с его автомобилями и заявками.
  class ClientsController < ApplicationController
    PER_PAGE = 20
    SORTABLE_COLUMNS = %w[name phone created_at].freeze
    DEFAULT_SORT_COLUMN = 'created_at'
    DEFAULT_SORT_DIRECTION = 'desc'

    # GET /clients
    def index
      @clients = current_tenant.clients
                               .includes(:telegram_user, :vehicles, :bookings)
                               .order(sort_column => sort_direction)

      @clients = @clients.where('name ILIKE :q OR phone ILIKE :q', q: "%#{params[:q]}%") if params[:q].present?

      @clients = @clients.page(params[:page]).per(PER_PAGE)
    end

    # GET /clients/:id
    def show
      @client = current_tenant.clients.includes(:telegram_user, :vehicles, :bookings, chats: :messages).find(params[:id])
    end

    private

    def sort_column
      SORTABLE_COLUMNS.include?(params[:sort]) ? params[:sort] : DEFAULT_SORT_COLUMN
    end

    def sort_direction
      %w[asc desc].include?(params[:direction]) ? params[:direction] : DEFAULT_SORT_DIRECTION
    end
  end
end
