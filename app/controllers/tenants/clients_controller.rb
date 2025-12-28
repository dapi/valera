# frozen_string_literal: true

module Tenants
  # Контроллер для просмотра клиентов tenant'а
  #
  # Показывает список клиентов с пагинацией и поиском,
  # а также детальную информацию о клиенте с его автомобилями и заявками.
  class ClientsController < ApplicationController
    PER_PAGE = 20

    # GET /clients
    def index
      @clients = current_tenant.clients
                               .includes(:telegram_user, :vehicles, :bookings)
                               .order(created_at: :desc)

      @clients = @clients.where('name ILIKE :q OR phone ILIKE :q', q: "%#{params[:q]}%") if params[:q].present?

      @clients = @clients.page(params[:page]).per(PER_PAGE)
    end

    # GET /clients/:id
    def show
      @client = current_tenant.clients.includes(:telegram_user, :vehicles, :bookings).find(params[:id])
    end
  end
end
