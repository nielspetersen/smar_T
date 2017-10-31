class Driver < ActiveRecord::Base
  belongs_to :user
  has_many :tours, dependent: :destroy
  has_one :vehicle

  before_update :timeToInt
  
  attr_accessor :hour, :minute
  
  validates :working_time, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 1440 }
  
  delegate :company, to: :user

  def active_tour(algorithm = nil, status = nil)
    options = {}
    options[:driver_id] = self.id
    if algorithm then options[:algorithm] = algorithm end
    if status then options[:status] = status end
    Tour.where(options).last
  end

  def has_tours?
    Tour.where(driver: self).any?
  end

  def tours(select = {})
    where_clause = { driver: self }.merge(select)
    Tour.where(where_clause)
  end

  def timeToInt
    if hour.nil?
     self.hour = 0
    end
    if minute.nil?
      self.minute = 0
    end
    self.working_time = 60 * Integer(hour) + Integer(minute)
  end
  
  def intToTime
    self.hour = Integer(working_time) / 60
    self.minute = Integer(working_time) % 60
  end
end
