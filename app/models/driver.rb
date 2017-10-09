class Driver < ActiveRecord::Base
  belongs_to :user
  has_many :tours, dependent: :destroy
  has_one :vehicle
  
  validates :working_time, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 1440 }
  
  delegate :company, to: :user

  def active_tour(algorithm = nil, status = nil)
    options = {}
    options[:driver_id] = self.id
    if algorithm then options[:algorithm] = algorithm end
    if status then options[:status] = status end
    Tour.where(options).last
  end
end
