# frozen_string_literal: true

# Vehicle represents a car belonging to a Client.
# Each client can have multiple vehicles.
class Vehicle < ApplicationRecord
  belongs_to :client

  has_many :bookings, dependent: :nullify

  validates :brand, presence: true

  # Delegate tenant access through client
  delegate :tenant, to: :client

  # Returns a formatted display name for the vehicle
  # @example "Toyota Camry (2020)" or "BMW X5" if no year
  def display_name
    parts = [ brand, model ].compact_blank
    parts << "(#{year})" if year.present?
    parts.join(' ')
  end

  # Returns formatted plate number or nil
  def formatted_plate
    plate_number&.upcase&.gsub(/\s+/, ' ')&.strip
  end
end
