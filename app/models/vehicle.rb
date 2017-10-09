class Vehicle < ActiveRecord::Base
  belongs_to :company
  belongs_to :driver

  validates :driver_id, uniqueness: true, :allow_nil => true

  # Koordinaten aus Adresse
  geocoded_by :position
  after_validation :geocode

end
