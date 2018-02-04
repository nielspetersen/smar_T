class Order < ActiveRecord::Base
  belongs_to :customer
  attr_accessor :hour, :minute

  validates :location, :customer, presence: true  
  validate :end_date_after_start_date?
  validate :start_time_in_past?, on: :create

  before_validation :timeToInt
  after_validation :geocode_locations, :process_validity_geocoords

  before_destroy :destroy_associated_order_tour

  # allow search on attributes
  scoped_search on: [:order_ref, :location, :comment], complete_value: true

  def start_time_in_past?
    if self.start_time
      if self.start_time < Time.now
        errors.add(:start_time, I18n.t('start_time_in_past'))
      end
    end
  end

  def end_date_after_start_date?
    if self.start_time && self.end_time
      if self.end_time < self.start_time
        errors.add(:end_time, I18n.t('end_time_after_start_time'))
      end
    end
  end

  # update geo coordiantes for pickup and delivery location
  def geocode_locations
    coords = Geocoder.coordinates(self.location)
    if coords.nil?
      self.lat = nil
      self.long = nil
    else
      self.lat = coords[0]
      self.long = coords[1]
    end
  end

  # checks if geocoordinates for order exists and updates status accordingly
  def process_validity_geocoords
    unless self.status == OrderStatusEnum::COMPLETED
      if self.lat && self.long
        if self.get_assigned_tour
          self.status = OrderStatusEnum::ASSIGNED
        else
          self.status = OrderStatusEnum::ACTIVE
        end
      else
        self.status = OrderStatusEnum::INVALID
      end
    end
  end

  # returns assigned tour if exists
  def get_assigned_tour
    order_tour = OrderTour.find_by_order_id(self.id)
    if order_tour.blank?
      return nil
    else
      order_tour.tour
    end
  end

def timeToInt
    if self.hour || self.minute
    	if hour.nil?
     		self.hour = 0
    	end
    	if minute.nil?
      	self.minute = 0
    	end
    	self.duration = 60 * Integer(hour) + Integer(minute)
    end
  end
  
  def intToTime
    self.hour = Integer(duration) / 60
    self.minute = Integer(duration) % 60
  end

  # destroys order_tours which are associated with this order and updates places of corresponding tour
  def destroy_associated_order_tour
    order_tours = OrderTour.where(order: self)
    order_tours.each do |order_tour|
      tour = order_tour.tour
      order_tour.destroy
      if tour
        tour.update_place_order_tours
      end
    end
  end
end
