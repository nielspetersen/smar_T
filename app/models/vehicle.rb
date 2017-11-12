class Vehicle < ActiveRecord::Base
  belongs_to :company
  belongs_to :driver

  validates :driver_id, uniqueness: true, :allow_nil => true
  validates :registration_number, uniqueness: true, :allow_nil => true, :allow_blank => true
  validates :position, presence: true

  # Koordinaten aus Adresse
  geocoded_by :position
  after_validation :geocode

end
