class Depot < ActiveRecord::Base
  belongs_to :company
   
  validates :address, presence: true
  validates :duration, numericality: { only_integer: true, greater_than_or_equal_to: 0}

  # Koordinaten aus Adresse
  geocoded_by :address
  after_validation :geocode

end
