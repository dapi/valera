# frozen_string_literal: true

require 'test_helper'

module CsvExporters
  class BookingsExporterTest < ActiveSupport::TestCase
    def setup
      @tenant = tenants(:one)
      @booking = bookings(:one)
    end

    test 'generates CSV with UTF-8 BOM' do
      bookings = @tenant.bookings
      csv = BookingsExporter.new(bookings).call

      assert csv.start_with?("\xEF\xBB\xBF"), 'CSV should start with UTF-8 BOM'
    end

    test 'generates CSV with headers' do
      bookings = @tenant.bookings
      csv = BookingsExporter.new(bookings).call
      lines = csv.split("\n")

      assert_includes lines.first, 'Номер'
      assert_includes lines.first, 'Клиент'
      assert_includes lines.first, 'Телефон'
      assert_includes lines.first, 'Автомобиль'
      assert_includes lines.first, 'Дата'
      assert_includes lines.first, 'Детали'
    end

    test 'includes booking data in CSV' do
      bookings = @tenant.bookings.includes(:client, :vehicle)
      csv = BookingsExporter.new(bookings).call

      assert_includes csv, @booking.public_number
      assert_includes csv, @booking.client.display_name
    end

    test 'uses semicolon as column separator' do
      bookings = @tenant.bookings
      csv = BookingsExporter.new(bookings).call
      lines = csv.split("\n")

      assert_includes lines.first, ';'
    end

    test 'handles bookings without vehicle' do
      @booking.update!(vehicle: nil)
      bookings = @tenant.bookings.includes(:client, :vehicle)

      csv = BookingsExporter.new(bookings).call

      assert_kind_of String, csv
    end

    test 'formats vehicle as brand and model' do
      vehicle = vehicles(:one)
      @booking.update!(vehicle: vehicle)
      bookings = @tenant.bookings.includes(:client, :vehicle)

      csv = BookingsExporter.new(bookings).call

      assert_includes csv, vehicle.brand
      assert_includes csv, vehicle.model
    end
  end
end
