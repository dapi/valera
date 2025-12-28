# frozen_string_literal: true

require 'test_helper'

module CsvExporters
  class ClientsExporterTest < ActiveSupport::TestCase
    def setup
      @tenant = tenants(:one)
      @client = clients(:one)
    end

    test 'generates CSV with UTF-8 BOM' do
      clients = @tenant.clients
      csv = ClientsExporter.new(clients).call

      assert csv.start_with?("\xEF\xBB\xBF"), 'CSV should start with UTF-8 BOM'
    end

    test 'generates CSV with headers' do
      clients = @tenant.clients
      csv = ClientsExporter.new(clients).call
      lines = csv.split("\n")

      assert_includes lines.first, 'Имя'
      assert_includes lines.first, 'Телефон'
      assert_includes lines.first, 'Telegram'
      assert_includes lines.first, 'Дата регистрации'
      assert_includes lines.first, 'Автомобили'
      assert_includes lines.first, 'Заявки'
    end

    test 'includes client data in CSV' do
      clients = @tenant.clients.includes(:telegram_user, :vehicles, :bookings)
      csv = ClientsExporter.new(clients).call

      assert_includes csv, @client.display_name
      assert_includes csv, @client.phone
    end

    test 'uses semicolon as column separator' do
      clients = @tenant.clients
      csv = ClientsExporter.new(clients).call
      lines = csv.split("\n")

      assert_includes lines.first, ';'
    end

    test 'handles clients without telegram username' do
      @client.telegram_user.update!(username: nil)
      clients = @tenant.clients.includes(:telegram_user)

      csv = ClientsExporter.new(clients).call

      assert_kind_of String, csv
    end

    test 'formats telegram username with @ prefix' do
      @client.telegram_user.update!(username: 'test_user')
      clients = @tenant.clients.includes(:telegram_user)

      csv = ClientsExporter.new(clients).call

      assert_includes csv, '@test_user'
    end
  end
end
