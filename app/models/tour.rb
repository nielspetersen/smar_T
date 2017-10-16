class Tour < ActiveRecord::Base
  belongs_to :driver
  has_many :order_tours, -> { order(place: :asc) }, dependent: :delete_all

  def duration
    tour_duration = 0
    self.order_tours.each do |order_tour|
      tour_duration += order_tour.time
      tour_duration += order_tour.duration
    end
    tour_duration
  end

  def completed?
    self.status == StatusEnum::COMPLETED
  end
end
