# frozen_string_literal: true

module Tenants
  module Clients
    # Handles CSV export of clients for current tenant.
    #
    # @example Export clients
    #   POST /clients/export
    #   -> Downloads clients-2024-01-15.csv
    #
    class ExportsController < Tenants::ApplicationController
      # POST /clients/export
      def create
        clients = current_tenant.clients.includes(:telegram_user, :vehicles, :bookings)
        csv = CsvExporters::ClientsExporter.new(clients).call

        send_data csv,
                  filename: "clients-#{Date.current}.csv",
                  type: 'text/csv; charset=utf-8'
      end
    end
  end
end
