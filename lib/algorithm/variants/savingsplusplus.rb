require "algorithm/variants/models/combinedtourpair"

module Algorithm
  module Variants

    class SavingsPlusPlus < Heuristic

      def run(day_orders = [], day_drivers = [])
        while day_orders.any? && day_drivers.any? do
          # reset driver for new iteration
          @driver = nil
          day_tours = init(day_orders, day_drivers)
          optimize(day_tours)
          saveTours(day_tours, day_orders, day_drivers)
        end
      end

      def init(day_orders, day_drivers)
        day_tours = []
        if day_orders.any?
          first_order = day_orders[0]
          @driver = best_driver_for_order(first_order, day_drivers) # restriction check in best_driver
          day_orders.delete_at(0)
          # check if compatbile driver / vehicle exists
          if @driver
            tour = build_trivial_tour(first_order, @driver)
            day_tours.push(tour)

            # reverse for-loop because we are deleting elements
            for i in (day_orders.count - 1).downto(0)
              order = day_orders[i]
              #build trivial tour for every order
              trivial_tour = build_trivial_tour(order, @driver)
              if check_restriction(trivial_tour, @driver)
                day_tours.push(trivial_tour)
                day_orders.delete(order)
              end
            end
            return day_tours
          else
            init(day_orders, day_drivers) # recursive call
          end
        end
        return day_tours
      end

      def optimize(day_tours)
        compatible_tour_pairs = create_compatible_tour_pairs(day_tours) # also calculates duration of the tours

        if compatible_tour_pairs.any?
          calc_combined_tour_pair_savings(compatible_tour_pairs)
          # sort saving descending to start with the biggest saving
          compatible_tour_pairs.sort_by! { | compatible_tour | compatible_tour.saving }.reverse!
          while compatible_tour_pairs[0].saving >= 0 do
            # first tour pair (ti, tj) has highest saving
            best_saving_tour_pair = compatible_tour_pairs.slice!(0)
            best_saving_tour = create_tour_by_order_tours(best_saving_tour_pair.order_tours)

            compatible_tour_pairs.map! { | compatible_tour_pair |
              if compatible_tour_pair.tour1 == best_saving_tour_pair.tour2 ||
                 compatible_tour_pair.tour2 == best_saving_tour_pair.tour2
                # remove tour pairs consisting of tj
                nil
              elsif compatible_tour_pair.tour1 == best_saving_tour_pair.tour1
                # replace ti by combined tour with highest saving
                compatible_tour_pair.tour1 = best_saving_tour
                compatible_tour_pair.order_tours = extract_order_tours(compatible_tour_pair.tour1, compatible_tour_pair.tour2)
                combined_tour = create_tour_by_order_tours(compatible_tour_pair.order_tours)
                if check_restriction(combined_tour, @driver)
                  calc_saving_for_combined_tour_pair(compatible_tour_pair)
                  compatible_tour_pair
                else
                  nil
                end
              elsif compatible_tour_pair.tour2 == best_saving_tour_pair.tour1
                # replace ti by combined tour with highest saving
                compatible_tour_pair.tour2 = best_saving_tour
                compatible_tour_pair.order_tours = extract_order_tours(compatible_tour_pair.tour1, compatible_tour_pair.tour2)
                combined_tour = create_tour_by_order_tours(compatible_tour_pair.order_tours)
                if check_restriction(combined_tour, @driver)
                  calc_saving_for_combined_tour_pair(compatible_tour_pair)
                  compatible_tour_pair
                else
                  nil
                end
              else
                # if tour_pair does not partially contain best_saving_tour
                compatible_tour_pair
              end
            }.compact!

            update_day_tours(day_tours, best_saving_tour_pair, best_saving_tour)

            if compatible_tour_pairs.any?
              compatible_tour_pairs.sort_by! { | compatible_tour_pair | compatible_tour_pair.saving }.reverse!
            else
              # break the execution of function if no more compatible_tour_pairs exist
              break
            end
          end
        end
      end

      def saveTours(day_tours, day_orders, day_drivers)
        tours_with_quality = []
        day_tours.each do |day_tour|
          rating = quality_function(day_tour)
          tours_with_quality.push([rating, day_tour])
        end
        # retrieve tour with lowest rating / result of quality_function
        if tours_with_quality.any?
          best_tour = tours_with_quality.min_by { |rating, day_tour| rating }[1]
          best_tour.save
          # single deployment of driver
          day_drivers.delete(best_tour.driver)
          day_tours.delete(best_tour)
        end

        # for remaining tours in day_tours search for best driver
        for i in (day_tours.count - 1).downto(0)
          tour = day_tours[i]
          driver = best_driver_for_tour(tour, day_drivers)
          if driver
            tour.driver = driver
            tour.save
            day_drivers.delete(driver)
            day_tours.delete(tour)
          else
            order_tours = tour.order_tours.map! { |order_tour| order_tour if ["pickup", "delivery"].include?(order_tour.kind) }.compact!
            order_tours.each do |order_tour|
              day_orders.push(order_tour.order)
            end
          end
        end
      end

      # update the time attribute for order tour depending of prior order tour
      def update_time(order_tours, index = 1)
        time = time_for_distance(order_tours[index - 1], order_tours[index])
        order_tours[index].time = time
      end

      private

        def best_driver_for_order(order, drivers)
          #for identifying the best driver among possible drivers
          compatible_trivial_tours = []
          drivers.each do |driver|
            trivial_tour = build_trivial_tour(order, driver)
            if check_restriction(trivial_tour, driver)
              compatible_trivial_tours.push(trivial_tour)
            end
          end

          unless compatible_trivial_tours.empty?
            #return driver with lowest tour duration
            driver = compatible_trivial_tours.min_by { |tour| tour.duration }.driver # return tours with lowest tour duration
            compatible_trivial_tours.map! { |tour| nil } # to delete them from memory

            return driver
          end
          return nil
        end

        def best_driver_for_tour(tour, drivers)
          compatible_drivers_for_tour = []
          drivers.each do |driver|
            tour.driver = driver
            if check_restriction(tour, driver)
              compatible_drivers_for_tour.push([driver, tour.duration])
            end
          end

          unless compatible_drivers_for_tour.empty?
            best_driver = compatible_drivers_for_tour.min_by { |driver, duration| duration }[0]
            best_driver
          else
            nil
          end
        end

        def build_trivial_tour(order, driver)
          trivial_tour = TempTour.new(driver: driver, order_tours: [])
          # starting position
          vehicle_position = create_vehicle_position(driver)
          vehicle_position.tour = trivial_tour
          vehicle_position.place = 0
          trivial_tour.order_tours.push(vehicle_position)

          # add depot / storage
          depot = create_depot()
          depot.tour = trivial_tour
          depot.place = 1
          trivial_tour.order_tours.push(depot)

          delivery = create_delivery(order)
          delivery.tour = trivial_tour
          delivery.place = 2
          trivial_tour.order_tours.push(delivery)

          home = create_home()
          home.tour = trivial_tour
          home.place = 3
          trivial_tour.order_tours.push(home)

          update_order_tour_times(trivial_tour.order_tours)
          return trivial_tour
        end

        # returns compatible combinations of given tours as array of CombinedTourPairs objects
        def create_compatible_tour_pairs(tours_1, tours_2 = nil)
          tour_pairs = []
          if tours_2.blank?
            # build cartesian product of all day_tours without product of same tour and nil objects
            tour_pairs = tours_1.product(tours_1).map { |x, y| [x, y] if x != y }.compact
          else
            tour_pairs = tours_1.product(tours_2)
          end
          compatible_combined_tours = []
          tour_pairs.each do |tour1, tour2|
            combined_order_tours_array = extract_order_tours(tour1, tour2)

            combined_tour = create_tour_by_order_tours(combined_order_tours_array)
            if check_restriction(combined_tour, @driver)
              combined_tour_pair = Models::CombinedTourPair.new(tour1, tour2, combined_order_tours_array)
              compatible_combined_tours.push(combined_tour_pair)
            end
            # destroy temporary object for checking restriction
            combined_tour = nil
          end
          compatible_combined_tours
        end

        def calc_combined_tour_pair_savings(compatible_tour_pairs)
          compatible_tour_pairs.each do |combined_tour_pair|
            calc_saving_for_combined_tour_pair(combined_tour_pair)
          end
        end

        def calc_saving_for_combined_tour_pair(combined_tour_pair)
          combined_tour = create_tour_by_order_tours(combined_tour_pair.order_tours)
          combined_tour_duration = calc_tour_duration(combined_tour.order_tours)
          # if > 0 means the combined tours offers saving
          combined_tour_pair.saving = (combined_tour_pair.tour1.duration + combined_tour_pair.tour2.duration) - combined_tour_duration
        end


        def update_day_tours(day_tours, combined_tour_pair, combined_tour)
          # replace tour 1 with combined tour
          day_tours.map! { |tour|
            if tour.equal?(combined_tour_pair.tour1)
              combined_tour
            else
              tour
            end
          }

          # remove tour 2  / tj from day tours
          day_tours.delete(combined_tour_pair.tour2)
        end

        def create_tour_by_order_tours(order_tours)
          new_tour = TempTour.new(driver: @driver)
          new_order_tours = []
          order_tours.each_with_index do |order_tour, index|
            new_tour_order_tour = order_tour.dup
            new_tour_order_tour.tour = new_tour
            new_tour_order_tour.place = index
            new_order_tours.push(new_tour_order_tour)
          end
          new_tour.order_tours = new_order_tours
          update_order_tour_times(new_order_tours)
          new_tour
        end

      def create_vehicle_position(driver)
        vehicle_position = TempOrderTour.new()
        vehicle_position.order = nil
        vehicle_position.comment = "Start der Tour"
        vehicle_position.kind = "vehicle_position"
        vehicle_position.capacity_status = 0
        vehicle_position.time = 0

        return vehicle_position
      end

      def create_home()
        home = TempOrderTour.new()
        home.order = nil
        home.comment = "Ende der Tour"
        home.kind = "home"

        return home
      end

        # erstellt OrderTour depot
      def create_depot()
        depot = TempOrderTour.new()
        depot.order = nil
        depot.comment = "Warenbestand auffüllen"
        depot.kind = "depot"

        return depot
      end

      def create_delivery(order)
        order_tour_delivery = TempOrderTour.new()
        order_tour_delivery.order = order
        order_tour_delivery.comment = order.comment
        order_tour_delivery.kind = "delivery"

        return order_tour_delivery
      end

      def create_pickup(order)
        order_tour_pickup = TempOrderTour.new
        order_tour_pickup.order = order
        order_tour_pickup.comment = order.comment
        order_tour_pickup.kind = "pickup"

        return order_tour_pickup
      end

        # Recalculates savings for all tour pairs containing tour
        def recalculate_savings(compatible_tour_pairs, tour)
          #updated_compatible_tour_pairs = create_compatible_tour_pairs(compatible_tour_pairs, [tour_pair])
          calc_combined_tour_pair_savings(updated_compatible_tour_pairs)
          compatible_tour_pairs.sort_by! { |combined_tour| combined_tour.saving }.reverse!
        end

        # extract order tours from arguments for using in CombinedTourPair object
        def extract_order_tours(tour1, tour2)
          # combine tours
          # ignore home (last element)
          tour1_part = tour1.order_tours[0..(tour1.order_tours.length - 2)].map { |tour| tour.dup }
          # ignore vehicle position and depot (first elements)
          tour2_part = tour2.order_tours[2..(tour2.order_tours.length - 1)].map { |tour| tour.dup }

          combined_order_tours_array = tour1_part.concat(tour2_part)
          combined_order_tours_array.each_with_index do  |order_tour, index|
            order_tour.tour = nil
            order_tour.place = index
          end

          return combined_order_tours_array
        end

        # cost function based on total duration of tour
        def quality_function(tour)
          driver = tour.driver
          order_tours = tour.order_tours.map { |order_tour| order_tour if ["pickup", "delivery"].include?(order_tour.kind) }.compact
          accum_duration = 0
          if order_tours.any?
            order_tours.each do |order_tour|
              trivial_tour = build_trivial_tour(order_tour.order, driver)
              accum_duration += trivial_tour.duration
            end

            if accum_duration == 0
              accum_duration = 1
            end

            return tour.duration / accum_duration.to_f
          else
            return 10000
          end
        end
    end
  end
end
