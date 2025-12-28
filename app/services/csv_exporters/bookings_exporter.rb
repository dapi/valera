# frozen_string_literal: true

module CsvExporters
  # Exports bookings to CSV format.
  #
  # @example
  #   bookings = tenant.bookings.includes(:client, :vehicle)
  #   csv = CsvExporters::BookingsExporter.new(bookings).call
  #   send_data csv, filename: "bookings-#{Date.current}.csv"
  #
  class BookingsExporter < BaseExporter
    private

    def headers
      [
        'Номер',
        'Клиент',
        'Телефон',
        'Автомобиль',
        'Дата',
        'Детали'
      ]
    end

    def row(booking)
      client = booking.client
      [
        booking.public_number,
        client&.display_name,
        client&.phone,
        vehicle_name(booking),
        format_datetime(booking.created_at),
        booking.details
      ]
    end

    def vehicle_name(booking)
      vehicle = booking.vehicle
      return nil unless vehicle

      [ vehicle.brand, vehicle.model ].compact.join(' ')
    end
  end
end
