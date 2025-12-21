class Lead < ApplicationRecord
  validates :name, presence: true
  validates :phone, presence: true
  validates :company_name, presence: true
end
