# frozen_string_literal: true

module Tenants
  # Контроллер для просмотра заявок tenant'а
  #
  # Показывает список заявок с пагинацией и фильтрацией по дате,
  # а также детальную информацию о заявке.
  class BookingsController < ApplicationController
    PER_PAGE = 20

    # GET /bookings
    def index
      @bookings = current_tenant.bookings
                                .includes(:client, :vehicle)
                                .recent

      apply_date_filter
      @bookings = @bookings.page(params[:page]).per(PER_PAGE)
    end

    # GET /bookings/:id
    def show
      @booking = current_tenant.bookings.includes(:client, :vehicle, :chat).find(params[:id])
    end

    private

    def apply_date_filter
      apply_date_from_filter
      apply_date_to_filter
    end

    def apply_date_from_filter
      return unless params[:date_from].present?

      date = Date.parse(params[:date_from])
      @bookings = @bookings.where('bookings.created_at >= ?', date.beginning_of_day)
    rescue Date::Error
      flash.now[:alert] = t('tenants.bookings.index.invalid_date_format')
    end

    def apply_date_to_filter
      return unless params[:date_to].present?

      date = Date.parse(params[:date_to])
      @bookings = @bookings.where('bookings.created_at <= ?', date.end_of_day)
    rescue Date::Error
      flash.now[:alert] = t('tenants.bookings.index.invalid_date_format')
    end
  end
end
