# frozen_string_literal: true

module CsvExporters
  # Exports clients to CSV format.
  #
  # @example
  #   clients = tenant.clients.includes(:telegram_user, :vehicles, :bookings)
  #   csv = CsvExporters::ClientsExporter.new(clients).call
  #   send_data csv, filename: "clients-#{Date.current}.csv"
  #
  class ClientsExporter < BaseExporter
    private

    def headers
      [
        'Имя',
        'Телефон',
        'Telegram',
        'Дата регистрации',
        'Автомобили',
        'Заявки'
      ]
    end

    def row(client)
      [
        client.display_name,
        client.phone,
        telegram_username(client),
        format_datetime(client.created_at),
        client.vehicles.size,
        client.bookings.size
      ]
    end

    def telegram_username(client)
      username = client.telegram_user_username
      username.present? ? "@#{username}" : nil
    end
  end
end
