class Depot < ActiveRecord::Base
  belongs_to :company
   
  before_validation :timeToInt
  
  attr_accessor :hour, :minute

  validates :address, presence: true
  validates :duration, numericality: { only_integer: true, greater_than_or_equal_to: 0}

  # Koordinaten aus Adresse
  geocoded_by :address
  after_validation :geocode

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

end
