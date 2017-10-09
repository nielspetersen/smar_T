require 'algorithm/enums/algorithm_enum'
require 'algorithm/enums/status_enum'

module Algorithm
  module Variants

    class Heuristic

      #Override of ruby built in object initialization
      def initialize(company)
        @company = company unless company.nil?
      end

      def run(orders = [], vehicles = [])
        raise NotImplementedError, "Subclasses must define `run`."
      end

      def check_restriction(tour, driver)
        tour_stops = tour.is_a?(Array) ? tour : tour.order_tours
        if @company.time_window_restriction?
          if time_window?(tour_stops)
            return false
          end
        end

        if @company.capacity_restriction?
          if capacity?(tour_stops, driver)
            return false
          end
        end

        if @company.work_time_restriction?
          if working_time?(tour_stops, driver)
            return false
          end
        end
        return true # liefert true, wenn alle Beschränkungen eingehalten werden
      end

      def calc_tour_duration(tour)
        tour_time = 0
        if tour.kind_of?(Array)
          tour.each do |order_tour|
            tour_time += order_tour.time # Fahrzeit
            if order_tour.duration # Manche Aufträge haben ggf. keine Arbeitszeit
              tour_time += order_tour.duration # Arbeitszeit
            end
          end
        end
        # damit nicht durch 0 geteilt wird
        if tour_time == 0
          tour_time = 1
        end
        tour_time
      end

      # updating capacity starting from index
      def update_capacity(tour, index = 1)
        order_tours = tour.order_tours
        for i in index..(order_tours.length - 1)
          updated_capacity_status = order_tours[(i-1)].capacity_status + capacity_summand(order_tours[i])
          order_tours[i].update(capacity_status: updated_capacity_status)
        end
      end

      def update_order_tour_times(order_tours)
        for index in 1..(order_tours.length - 1)
          update_time(order_tours, index)
        end
      end

      # Berechnet OrderTour.time neu
      def update_time(order_tours, index = 1)
        time = time_for_distance(order_tours[index - 1], order_tours[index])
        order_tours[index].update_attributes(time: time)
      end

      #die Zeit für die Fahrt von order_tour1 nach order_tour2
      def time_for_distance(order_tour1, order_tour2)
        # Google Maps
        driveTime = DriveTimeBetweenAddresses.new(order_tour1.location,
                                                  order_tour2.location,
                                                  @company.google_maps_api_key)
        time = driveTime.cached_drive_time_in_minutes()
        time # return
      end

      private

        def capacity?(tour, driver) # liefert true, wenn gegen restriction verstoßen wird
          # tour.each_with_index do |order_tour, index|
          #   # Wenn eine bei einem Punkt in Tour die Capacity überschritten wird
          #   if order_tour.capacity_status > driver.vehicle.capacity
          #     if @company.restriction.problem == "PP" # Und es ein PP ist,...
          #       #... dann soll ein Depot davor eingesetzt werden
          #       depot = create_depot()
          #       # Fahrzeug komplett entleeren
          #       depot.capacity = tour[index-1]*-1
          #       # Vor Verstoß einsetzen
          #       tour.insert(index-1, depot)
          #       # update capacity_status
          #       tour = update_capacity(tour, index)
          #     else
          #       return true # Wenn es PDP ist, dann Verstoß
          #     end
          #   elsif order_tour.capacity_status <= 0  # oder kleiner, gleich 0 ist
          #     if @company.restriction.problem == "DP" # Und es ein DP ist,...
          #       #... dann soll ein Depot davor eingesetzt werden
          #       depot = create_depot()
          #       # Fahrzeug vollbeladen
          #       depot.capacity = driver.capacity - tour[index-1]
          #       # Vor Verstoß einsetzen
          #       tour.insert(index-1, depot)
          #       # Capacity_status updaten
          #       tour = update_capacity(tour, index)
          #     else
          #       return true # Wenn es PDP ist, dann Verstoß
          #     end
          #   end
          # end
          return false
        end


        # Überprüfen ob Time Windows eingehalten werden
        def time_window?(tour) # liefert true, wenn gegen restriction verstoßen wird
          time_now = Time.now.to_i
          # Jede Order_tour überprüfen, ob der Zeitpunkt im Zeitfenster von Order ist
          tour.each_with_index do |order_tour, index|
            # only order tours with associated order have to fullfill time_window
            if ["delivery", "pickup"].include?(order_tour.kind)
              # Zeit bis zu Order_tour
              tour_until = tour[0..index]
              time_until = calc_tour_duration(tour_until)
              # time_now plus time of tour till order_tour
              time_point = time_now + (time_until * 60) # convert to seconds
              # time_point nach end_time oder vor starttime
              if time_point > order_tour.order.end_time.to_i  || time_point < order_tour.order.start_time.to_i
                return true
              end
            end
          end
          return false
        end

        # Überprüfen ob working time eingehalten wird
        # Kann dazu führen, kann das keine Tour gebildet wird! Passiert vor allem bei nur einem Fahrer
        def working_time?(tour_stops, driver) # liefert true, wenn gegen restriction verstoßen wird
          # Prüfen ob die Tourdauer > als working_time vom Driver
          if calc_tour_duration(tour_stops) > driver.working_time
            # true wenn tour zu lang ist
            return true
          end
          false
        end

        def create_vehicle_position(driver)
          # carrier.vehicle.position einsetzen als OrderTour
          vehicle_position = OrderTour.new()
          vehicle_position.order_id = nil
          # place (Platzierung) wird im commit gesetzt
          vehicle_position.comment = "Start der Tour"
          vehicle_position.kind = "vehicle_position"
          vehicle_position.capacity_status = 0
          vehicle_position.time = 0 # Keine Zeit vergangen
          vehicle_position.save

          return vehicle_position
        end

        def create_home()
          # home = @company.address
          home = OrderTour.new()
          home.order_id = nil
          home.comment = "Ende der Tour"
          home.kind = "home"
          # capacity_status (Ladestatus Fahrzeug) wird im algo gesetzt
          home.save

          return home
        end

        # erstellt OrderTour depot
        def create_depot()
          depot = OrderTour.new()
          depot.order_id = nil
          depot.comment = "Warenbestand auffüllen"
          depot.kind = "depot"
          depot.save

          return depot
        end

        def create_delivery(order)
          order_tour_delivery = OrderTour.new()
          order_tour_delivery.order_id = order.id
          order_tour_delivery.comment = order.comment
          order_tour_delivery.kind = "delivery"
          order_tour_delivery.save

          return order_tour_delivery
        end

        def create_pickup(order)
          order_tour_pickup = OrderTour.new
          order_tour_pickup.order_id = order.id
          order_tour_pickup.comment = order.comment
          order_tour_pickup.kind = "pickup"
          order_tour_pickup.save

          return order_tour_pickup
        end

        # return positive capacity if order_tour increase loading, e.g. pickup
        # return negative capacity if order_tour decrease loading, e.g. delivery
        def capacity_summand(order_tour)
        case order_tour.try(:kind)
        when "pickup"
          return order_tour.capacity
        when "delivery"
          return order_tour.capacity * (-1)
        end
        return 0
      end
    end
  end
end
