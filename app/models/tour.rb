class Tour < ActiveRecord::Base
  include OrderToursHelper
  before_destroy :update_order_status

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

  # update the order of tour stops e.g. after removing order tours
  def update_place_order_tours
    self.order_tours.each_with_index do |order_tour, index|
      order_tour.update_attributes(place: index)
    end
  end

  def approved?
    self.status == StatusEnum::APPROVED
  end

  def started?
    self.status == StatusEnum::STARTED
  end

  def completed?
    self.status == StatusEnum::COMPLETED
  end

  private

    def update_order_status
      if self.approved? || self.started?
        self.order_tours.each do |order_tour|
          if ((available_order_tour_types).include? order_tour.kind) & order_tour.order
            assigned_order = order_tour.order
            assigned_order.update_attributes(status: OrderStatusEnum::ACTIVE)
          end
        end
      end
    end
end
