class Order < ActiveRecord::Base
  belongs_to :customer
 
  validates :location, :customer, presence: true  

  after_validation :geocode_locations

  # update geo coordiantes for pickup and delivery location
  def geocode_locations
    coords = Geocoder.coordinates(self.location)
    unless coords.nil?
      self.lat = coords[0]
      self.long = coords[1]
    end
  end

  # returns assigned tour if exists
  def get_assigned_tour
    order_tour = OrderTour.find_by_order_id(self.id)
    unless order_tour.blank?
      order_tour.tour
    end
  end
end
