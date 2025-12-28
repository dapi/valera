# frozen_string_literal: true

module Tenants
  module Bookings
    # Handles CSV export of bookings for current tenant.
    # Supports date range filtering via params.
    #
    # @example Export bookings
    #   POST /bookings/export
    #   -> Downloads bookings-2024-01-15.csv
    #
    # @example Export with date filter
    #   POST /bookings/export?date_from=2024-01-01&date_to=2024-01-31
    #
    class ExportsController < Tenants::ApplicationController
      # POST /bookings/export
      def create
        bookings = current_tenant.bookings.includes({ client: :telegram_user }, :vehicle)
        bookings = apply_date_filters(bookings)
        csv = CsvExporters::BookingsExporter.new(bookings).call

        send_data csv,
                  filename: "bookings-#{Date.current}.csv",
                  type: 'text/csv; charset=utf-8'
      end

      private

      def apply_date_filters(bookings)
        if params[:date_from].present?
          date_from = parse_date(params[:date_from])
          bookings = bookings.where('bookings.created_at >= ?', date_from.beginning_of_day) if date_from
        end

        if params[:date_to].present?
          date_to = parse_date(params[:date_to])
          bookings = bookings.where('bookings.created_at <= ?', date_to.end_of_day) if date_to
        end

        bookings
      end

      def parse_date(date_string)
        Date.parse(date_string)
      rescue ArgumentError
        nil
      end
    end
  end
end
