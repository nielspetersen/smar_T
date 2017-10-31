class TempOrderTour
  include ActiveModel::AttributeMethods, ActiveModel::Model

  attr_accessor :tour, :order, :place, :comment, :capacity_status, :time, :kind


  def save(tour)
    OrderTour.create(order: self.order,
                     tour: tour,
                     place: self.place,
                     comment: self.comment,
                     capacity_status: self.capacity_status,
                     time: self.time,
                     kind: self.kind)
  end

  def capacity
    if ["delivery", "pickup"].include?(self.kind) # one of them
      return self.order.capacity
    else
      return 0
    end
  end

  def duration
    case self.kind
      when "delivery", "pickup"
        return self.order.duration
      when "depot"
        depot = Depot.where(company: self.tour.driver.company).first
        if depot
          # time for loading and unloading
          return depot.duration
        else
          return 0
        end
      else # vehicle position or home
        return 0
    end
  end

  def location
    case self.kind
      when "delivery", "pickup"
        return self.order.location
      when "vehicle_position"
        return self.tour.driver.vehicle.position
      when "home"
        return self.tour.driver.company.address
      when "depot"
        depot = Depot.where(company: self.tour.driver.company).try(:first)
        if depot
          return depot.address
        else # if company has no depot return adress of company
          return self.tour.driver.company.address
        end
      else
        return ""
    end
  end

  def latitude
    case self.kind
      when "delivery", "pickup"
        return self.order.lat
      when "vehicle_position"
        return self.tour.driver.vehicle.latitude
      when "home"
        return self.tour.driver.company.latitude
      when "depot"
        depot = Depot.where(company: self.tour.driver.company).first
        if depot
          return depot.latitude
        else
          return self.tour.driver.company.latitude
        end
      else
        return nil
    end
  end

  def longitude
    case self.kind
      when "delivery", "pickup"
        return self.order.long
      when "vehicle_position"
        return self.tour.driver.vehicle.longitude
      when "home"
        return self.tour.driver.company.longitude
      when "depot"
        depot = Depot.where(company: self.tour.driver.company).first
        if depot
          return depot.longitude
        else
          return self.tour.driver.company.longitude
        end
      else
        return nil
    end
  end
end