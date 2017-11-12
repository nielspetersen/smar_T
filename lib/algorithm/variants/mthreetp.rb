module Algorithm
  module Variants

    class MThreeTP < Heuristic

      def initialize(company, algorithm)
        @algorithm = algorithm
        super(company)
      end

      def run(orders = [], vehicles = [])
        @orders = orders
        @drivers = vehicles

        if @company.restriction.try(:priorities)
          priority_groups = build_priority_groups(orders)
          priority_groups.each do |priority_group|
            unless priority_group.empty?
              matrix = build_matrix(priority_group)
              solve_matrix(matrix, priority_group.length)
            end
          end
        else # keine Prioritätsstufen
          # Matrix zwischen allen Drivern und allen Orders aufspannen
          matrix = build_matrix(orders)
          solve_matrix(matrix, orders.length)
        end

        unassigned_tours = OrderTour.where(tour_id: nil).all
        unassigned_tours.each do |tour|
          tour.destroy
        end

        Tour.all.each do |tour|
          if (tour.order_tours.length == 3)
            tour.destroy
          end
        end
      end

      # Matrix für Drivers und Orders
      def build_matrix(current_orders)
        matrix = []
        # MV oder SV wird automatisch durch die Anzahl von Drivern in Drivers beachtet
        # für jede Order...
        current_orders.each do |order|
          #... jeden Driver
          @drivers.each do |driver|
            possible_tour = [] # [Driver, Order, Tour]
            # die Zeit, samt Driver und Order, in possible_tour speichern
            possible_tour.push(driver)
            possible_tour.push(order)
            # die "echte" tour einfügen
            possible_tour.push(build_tour(order, driver))
            # anschließend in die matrix pushen
            matrix.push(possible_tour)
          end
        end

        matrix #return - matrix ist ein langes Array (beachten!)
      end

      # MMM durchführen
      def solve_matrix(matrix, order_count)
        # für jeder Order eine Tour finden
        tmp = 0
        if (matrix.present?)
          while tmp < order_count
            shortest_tour = matrix[0] # erste tour als shortest_tour
            # schnellste Tour ermitteln
            matrix.each do |possible_tour|
              # tour ist im dritten element [2] von possible_tour
              duration_shortest_tour = calc_tour_duration(shortest_tour[2])
              duration_tour = calc_tour_duration(possible_tour[2])
              # Wenn tourtime/|TR| kürzer ist...
              if (@algorithm == AlgorithmEnum::M3PDP)
                if (duration_shortest_tour/shortest_tour[2].length) > (duration_tour/shortest_tour[2].length)
                  shortest_tour = possible_tour # ...dann ist die possible_tour die neue shortest_tour
                end
              elsif (@algorithm == AlgorithmEnum::M3PDPDELTA)
                if((duration_shortest_tour - Driver.find(shortest_tour[0]).active_tour(@algorithm, StatusEnum::GENERATED).duration) > (duration_tour - Driver.find(possible_tour[0]).active_tour(@algorithm, StatusEnum::GENERATED).duration))
                  shortest_tour = possible_tour # ...dann ist die possible_tour die neue shortest_tour
                end
              end
            end
            # Driver die Tour (samt neuer Order) zuteilen
            #shortest_tour[0] = driver ; [1] = order ; [2] tour
            commit_order(shortest_tour)

            # Workaround für .time problem
            shortest_tour[2].each_with_index do |order_tour, index|
              if index > 0
                if order_tour.time != time_for_distance(shortest_tour[2][index-1], order_tour)
                  order_tour.time = time_for_distance(shortest_tour[2][index-1], order_tour)
                  order_tour.save
                  order_tour.tour.save
                end
              end
            end
            #update matrix - Löschen aller Einträge mit der Order und die Zeiten vom Fahrer updaten
            matrix = update_matrix(matrix, shortest_tour[0], shortest_tour[1])
            tmp += 1
          end
        end
      end

      # Nach einer Zuteilung die matrix erneuern
      def update_matrix(matrix, driver, order)
        # Alle Einträge in matrix mit order löschen
        length = matrix.length
        while length > 0
          element = matrix[length-1]
          if element[1].id == order.id # in element[1] steht die order
            matrix.delete_at(length-1)
          end
          length -= 1
        end
        # Alle Fahrzeiten von Driver updaten
        matrix.each_with_index do |tour, index|
          # Alle Einträge von Driver updaten
          if tour[0].id == driver.id # Driver steht in tour[0]
            # Tour neuberechnen
            tour[2] = build_tour(tour[1], tour[0])
          end
        end
        matrix
      end

      # Erstellt die OrderTour objekte und speichert die neue Tour und OrderTour in der DB
      def commit_order(shortest_tour)
        driver = shortest_tour[0]
        order = shortest_tour[1]
        tour = shortest_tour[2]

        # driver.tour kopieren, um neue OrderTour einzufügen
        driver_tour = Tour.where(driver: driver, status: StatusEnum::GENERATED, algorithm: @algorithm).take
        # Tour erstellen, falls keine existiert
        if driver_tour.nil?
          driver_tour = Tour.create(driver: driver, status: StatusEnum::GENERATED, algorithm: @algorithm)
        end
        #Neue Order_Tours identifizieren und in DB anlegen
        tour.each do |order_tour|
          # Wenn OrderTour noch nicht existiert...
          if order_tour.id.nil?
            # ...Element anlegen in DB speichern
            if order_tour.duration.nil?
              #order_tour.duration = 0
            end


          end
          order_tour.tour_id = driver_tour.id
          # Änderungen (wie place und time speichern)
          order_tour.save
          # .place anpassen
          unless order_tour.id.nil?
            if order_tour.place != OrderTour.where(id: order_tour.id) && OrderTour.find(order_tour.id)
              ot = OrderTour.find(order_tour.id)
              ot.place = order_tour.place
              ot.save
            end
          end
        end
        # Duration setzen
        # Tour speichern und Faher zuordnen
        # Order deaktivieren, damit sie in nächsten Planungen nicht versehentlich verplant wird
        # FIXME - Für Produkivbetrieb wieder einkommentieren
        # ToDo
        # order.active = false
        # order.save
      end

      def build_tour(order, driver)
        unless @company.restriction.nil?
          if @company.restriction.problem == "PDP"
            tour = insertion_pdp(order, driver)
          elsif @company.restriction.problem == "DP"
            tour = insertion_dp(order, driver)
          elsif @company.restriction.problem == "PP"
            tour = insertion_pp(order, driver)
          end
          tour
        else
          return insertion_dp(order, driver)
        end
      end

      def insertion_pdp(order, driver)
        # todo
      end

      def insertion_dp(order, driver)
        existing_tour = []
        unless driver.active_tour(@algorithm, StatusEnum::GENERATED).nil?
          active_tour = driver.active_tour(@algorithm, StatusEnum::GENERATED).order_tours
          active_tour.each do |tour_element|
            existing_tour.push(tour_element)
          end
        end

        if existing_tour.empty?
          driver_tour = Tour.create(driver: driver, status: StatusEnum::GENERATED, algorithm: @algorithm)

          vehicle_position = create_vehicle_position(driver)
          vehicle_position.tour_id = driver_tour.id
          vehicle_position.save

          depot = create_depot()
          depot.tour_id = driver_tour.id
          depot.save

          home = create_home()
          home.tour_id = driver_tour.id
          home.save

          existing_tour.push(vehicle_position)
          existing_tour.push(depot)
          existing_tour.push(home)
        end

        best_tour = []
        existing_tour.each_with_index do |location, index|
          if index + 2 == existing_tour.length
            break
          end

          new_tour = clone_array(existing_tour)
          new_tour.insert(index + 2, create_delivery(order))

          update_time(new_tour, index+2)

          unless @company.restriction.nil?
            if @company.restriction.capacity_restriction
              #  update_capacity(new_tour, index+2) // todo
            end
          end

          if !check_restriction(new_tour, driver)
            break
          end

          if best_tour.length < new_tour.length
            best_tour = clone_array(new_tour)
          else
            if calc_tour_duration(new_tour) < calc_tour_duration(best_tour)
              best_tour = clone_array(new_tour)
            end
          end
        end

        if best_tour.empty?
          best_tour.push(OrderTour.new(time: 10000, kind: "home"))
        end

        best_tour.each_with_index do |order_tour, index|
          order_tour.place = index
        end

        best_tour
      end

      def insertion_pp(order, driver)
        # todo
      end

      def build_priority_groups(orders)
        prioA = []
        prioB = []
        prioC = []
        prioD = []
        prioE = []
        orders.each do |order|
          unless order.customer.nil?
            if order.customer.priority == "A"
              prioA.push(order)
            elsif order.customer.priority == "B"
              prioB.push(order)
            elsif order.customer.priority == "C"
              prioC.push(order)
            elsif order.customer.priority == "D"
              prioD.push(order)
            else
              prioE.push(order)
            end
          else
            prioD.push(order)
          end
        end
        prioArray =[prioA, prioB, prioC, prioD, prioE]
        prioArray
      end

      def clone_array (old_array)
        new_array = []
        old_array.each do |element|
          new_array.push(element.clone)
        end
        new_array
      end

    end
  end
end
