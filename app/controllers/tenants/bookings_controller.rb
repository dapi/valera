# frozen_string_literal: true

module Tenants
  # Контроллер для просмотра заявок tenant'а
  #
  # Показывает список заявок с пагинацией и фильтрацией по дате,
  # а также детальную информацию о заявке.
  class BookingsController < ApplicationController
    include ErrorLogger
    PER_PAGE = 20
    PERIOD_FILTERS = {
      'today' => -> { Date.current.beginning_of_day },
      'week' => -> { 1.week.ago.beginning_of_day },
      'month' => -> { 1.month.ago.beginning_of_day }
    }.freeze

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
      apply_period_filter
      apply_custom_date_range
    end

    def apply_period_filter
      return unless PERIOD_FILTERS[params[:period]]

      start_date = PERIOD_FILTERS[params[:period]].call
      @bookings = @bookings.where('bookings.created_at >= ?', start_date)
    end

    def apply_custom_date_range
      apply_date_from_filter
      apply_date_to_filter
    end

    def apply_date_from_filter
      return unless params[:date_from].present?

      date = Date.parse(params[:date_from])
      @bookings = @bookings.where(Booking.arel_table[:created_at].gteq(date.beginning_of_day))
    rescue Date::Error => e
      handle_date_error(e, :date_from)
    end

    def apply_date_to_filter
      return unless params[:date_to].present?

      date = Date.parse(params[:date_to])
      @bookings = @bookings.where(Booking.arel_table[:created_at].lteq(date.end_of_day))
    rescue Date::Error => e
      handle_date_error(e, :date_to)
    end

    def handle_date_error(error, param)
      log_error(error, {
        controller: 'Tenants::BookingsController',
        action: 'apply_custom_date_range',
        param: param,
        value: params[param]
      })
      flash.now[:alert] = t('tenants.bookings.index.invalid_date_format')
    end
  end
end
