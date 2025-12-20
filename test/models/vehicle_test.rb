# frozen_string_literal: true

require 'test_helper'

class VehicleTest < ActiveSupport::TestCase
  setup do
    @client = clients(:one)
    @vehicle = vehicles(:one)
  end

  test 'fixture is valid' do
    assert @vehicle.valid?
    assert @vehicle.persisted?
  end

  test 'belongs to client' do
    assert_respond_to @vehicle, :client
    assert_not_nil @vehicle.client
  end

  test 'validates brand presence' do
    vehicle = Vehicle.new(client: @client)
    assert_not vehicle.valid?
    assert vehicle.errors[:brand].any?
  end

  test 'has many bookings with nullify' do
    assert_respond_to @vehicle, :bookings
  end

  test 'delegates tenant through client' do
    assert_equal @vehicle.client.tenant, @vehicle.tenant
  end

  test 'display_name with brand and model' do
    vehicle = Vehicle.new(brand: 'Toyota', model: 'Camry')
    assert_equal 'Toyota Camry', vehicle.display_name
  end

  test 'display_name with year' do
    vehicle = Vehicle.new(brand: 'BMW', model: 'X5', year: 2020)
    assert_equal 'BMW X5 (2020)', vehicle.display_name
  end

  test 'display_name with brand only' do
    vehicle = Vehicle.new(brand: 'Honda')
    assert_equal 'Honda', vehicle.display_name
  end

  test 'formatted_plate returns uppercase stripped' do
    vehicle = Vehicle.new(brand: 'Test', plate_number: ' а123bc 777 ')
    assert_equal 'А123BC 777', vehicle.formatted_plate
  end

  test 'formatted_plate returns nil for blank plate' do
    vehicle = Vehicle.new(brand: 'Test', plate_number: nil)
    assert_nil vehicle.formatted_plate
  end
end
