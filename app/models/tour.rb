class Tour < ActiveRecord::Base
  include ToursHelper
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

  def duration_as_string
    total_duration = self.duration
    hours = total_duration / 60
    minutes = total_duration % 60 # remainder represents minutes

    return (hours.to_s + ' ' + I18n.t('attributes.hours') + ' ' + minutes.to_s + ' ' + I18n.t('attributes.minutes'))
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

  def remove_order_tour(order_tour = nil)
    # do not manipulate a already started or completed tour
    if self.approved?
      # only consider order tours which are part of the tour and have a valid type
      if order_tour.instance_of?(OrderTour) && order_tour.tour_id == self.id && is_editable_order_tour?(order_tour)
        assigned_order = Order.find(order_tour.order_id)
        # delete order_tour
        order_tour.destroy
        # change status of affected order to active
        if assigned_order
          assigned_order.update_attributes(status: OrderStatusEnum::ACTIVE)
        end
      end
    end
  end

  private

    def update_order_status
      if self.approved? || self.started?
        self.order_tours.each do |order_tour|
          if (is_editable_order_tour? && order_tour.order)
            assigned_order = order_tour.order
            assigned_order.update_attributes(status: OrderStatusEnum::ACTIVE)
          end
        end
      end
    end
end
