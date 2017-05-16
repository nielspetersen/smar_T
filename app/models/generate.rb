#Klasse zur Erstellung der Touren entsprechen der Konfiguration

class Generate

    #Variablen

    attr_accessor :drivers, :orders, :company, :user

    # Methoden

    # generiete die Touren für alle driver und orders entsprechend der company.restriction
    def generate_tours
        # Prüfen ob Prioritätsstufen bestehen
        if company.restriction.try(:priorities)
            # orders ändern zu array von arrays, für jede priority eine array
            orders_array = by_priority()
            # Die Order nach prio zuteilen
            orders_array.each do |prio_orders|
                # leere PrioGruppen ignorieren
                if prio_orders.present?
                    order_count = prio_orders.length
                    # Matrix für jede Prioritässtufe
                    matrix = build_matrix(prio_orders)

                    # jede Prioritätsstufe nacheinander bearbeiten
                    solve_matrix(matrix, order_count)
                end
            end
        else # keine Prioritätsstufen
            # Matrix zwischen allen Drivern und allen Orders aufspannen
            matrix = build_matrix(orders)

            # Alle Orders in Matrix zuteilen
            solve_matrix(matrix, orders.length)
        end
        # Touren löschen, die nur aus 3 OrderTours bestehen (vp, depot, home), also keine Order bearbeiten
        ##touren = Tour.where(company_id: company.id)
        touren = company.tours
        touren.each do |tour|
            # leere touren pdp löschen
            if tour.order_tours.length == 2 && company.restriction.problem == "PDP"
                tour.order_tours.each do |order_tour|
                    order_tour.destroy
                end
                tour.destroy
            # leere touren pd und pp löschen
            elsif tour.order_tours.length == 3
                tour.order_tours.each do |order_tour|
                    #order_tour.destroy ToDo
                end
                #tour.destroy ToDo
            end
        end
    end # end generate_tour()

    # Matrix für Drivers und Orders
    def build_matrix(current_orders)
        matrix = []
        # MV oder SV wird automatisch durch die Anzahl von Drivern in Drivers beachtet
        # für jede Order...
        current_orders.each do |order|
            #... jeden Driver
            drivers.each do |driver|
                possible_tour = [] # [Driver, Order, Tour]
                # die Zeit, samt Driver und Order, in possible_tour speichern
                possible_tour.push(driver)
                possible_tour.push(order)
                # die "echte" tour einfügen
                possible_tour.push(build_tour(order,driver))
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
                  duration_shortest_tour = calc_tour_time(shortest_tour[2])
                  duration_tour = calc_tour_time(possible_tour[2])

                  if((duration_shortest_tour - Driver.find(shortest_tour[0]).active_tour.duration) > (duration_tour - Driver.find(possible_tour[0]).active_tour.duration))
                      shortest_tour = possible_tour # ...dann ist die possible_tour die neue shortest_tour
                  end
              end
              # Driver die Tour (samt neuer Order) zuteilen
              #shortest_tour[0] = driver ; [1] = order ; [2] tour
              commit_order(shortest_tour[0], shortest_tour[1], shortest_tour[2])

              # Workaround für .time problem
              shortest_tour[2].each_with_index do |order_tour, index|
                  if index > 0
                      if order_tour.time != time_for_distance(shortest_tour[2][index-1], order_tour)
                          order_tour.time = time_for_distance(shortest_tour[2][index-1], order_tour)
                          order_tour.save
                          order_tour.tour.duration = calc_tour_time(shortest_tour[2])
                          order_tour.tour.save
                      end
                  end
              end
              #update matrix - Löschen aller Einträge mit der Order und die Zeiten vom Fahrer updaten
              matrix = update_matrix(matrix, shortest_tour[0], shortest_tour[1])
              tmp += 1
          end
        end
    end# end solve_matrix

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
        matrix # return
    end # end update_matrix()

    # Erstellt die OrderTour objekte und speichert die neue Tour und OrderTour in der DB
    def commit_order(driver, order, tour)
    # driver.tour kopieren, um neue OrderTour einzufügen
        driver_tour = Tour.where(driver_id: driver.id).take
        # Tour erstellen, falls keine existiert
        if driver_tour.nil?
            driver_tour = Tour.create(user_id: user.id, company_id: company.id, duration: 0)
        end
        #Neue Order_Tours identifizieren und in DB anlegen
        tour.each do |order_tour|
            # Wenn OrderTour noch nicht existiert...
            if order_tour.id.nil?
                # ...Element anlegen in DB speichern
                if order_tour.duration.nil?
                    order_tour.duration = 0
                end

                order_tour.tour_id = driver_tour.id

            end
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
        driver_tour.duration = calc_tour_time(tour)
        # Tour speichern und Faher zuordnen
        # Order deaktivieren, damit sie in nächsten Planungen nicht versehentlich verplant wird
        # FIXME - Für Produkivbetrieb wieder einkommentieren
        # ToDo
        # order.activ = false
        order.save
    end # end commit_order

    # liefert die neue Tour (aufbauend auf der alten) von Drivers inklusive Order
    def build_tour(order, driver)
        # Entsprechend dem Tourenplanungsproblem den Insertionalgorithmus aufrufen
        if company.restriction.problem == "PDP"
           tour = insertion_pdp(order, driver)
        elsif company.restriction.problem == "DP"
            tour = insertion_dp(order, driver)
        elsif company.restriction.problem == "PP"
            tour = insertion_pp(order, driver)
        end
        tour # return tour
    end # end build_tour()

    #nicht getestet
    # Insertionalgo für PDP
    def insertion_pdp(order, driver)
        # load tour vom driver (wenn eine besteht)
        old_tour = []

        # Alle OrderTour Elemente laden und old_tour befüllen
        unless driver.active_tour.nil?
            # sortiert nach place
            order_tours = driver.active_tour.order_tours
            order_tours = driver_tour.sort {|x,y| x.place <=> y.place}
            order_tours.each do |tour_element|
                old_tour.push(tour_element)
            end
        end

        #Wenn es keine alte Tour gab, neue Tour erzeugen
        if old_tour.empty?
            # Tour erzeugen
            driver_tour = Tour.create(driver_id: driver, duration: 0)
            # startpostion einfügen
            vehicle_position = create_vehicle_position(driver)
            vehicle_position.tour_id = driver_tour.id
            vehicle_position.place = 0
            vehicle_position.save
            # home einfügen - entspricht unternehmensadresse
            home = create_home(vehicle_position, driver)
            home.tour_id = driver_tour.id
            home.place = 1
            home.save
            # old_tour befüllen
            old_tour.push(vehicle_position)
            old_tour.push(home)
        end

        # Order in zwei OrderTours zerlegen
        # Pickup OrderTour
        order_tour_pickup = create_pickup(order)
        # Delivery OrderTour
        order_tour_delivery = create_delivery(order)
        # Array für beste tour
        best_tour = []
        new_tour = []

        # OrderTours an verschiedenen Positionen von old_tour einsetzen
        old_tour.each_with_index do |location_first, index_first|
            # Abbrechen bevor nach home eingesetzt wird
            if index_first+1 == old_tour.length
                break
            end

            #potenziell neue Tour erstellen
            new_tour = duplicate_tour_array(old_tour)

            # Pickup einsetzen
            new_tour.insert(index_first+1, order_tour_pickup)
            # OrderTour.time updaten
            new_tour = update_time(new_tour, index_first+1)

            # Wenn eine Capacity_restriction besteht...
            if company.restriction.capacity_restriction
                # ...Order.capacity_status updaten
                new_tour = update_capacity(new_tour_index_first)
            end

            # Delivery in new_tour einsetzen
            new_tour.each_with_index do |location_second, index_second|
                # Abbrechen bevor nach home eingesetzt wird
                if index_second+1 == new_tour.length
                    break
                end
                # Delivery erst nach Pickup einsetzen
                if index_second > index_first+1
                    #Delivery einsetzen
                    new_tour.insert(index_second+1, order_tour_delivery)

                    # OrderTour.time updaten
                    new_tour = update_time(new_tour, index_second+1)
                    # Wenn eine Capacity_restriction besteht...
                    if restriction.capacity_restriction
                        # ...Order.capacity_status updaten
                        new_tour = update_capacity(new_tour, index_second+1)
                    end
                    # Prüfen ob Beschränkungen eingehalten werden
                    if check_restriction(new_tour, order, driver)
                        break
                    end
                end

                # best_tour = erste new_tour
                if best_tour.length < new_tour.length
                    best_tour = duplicate_tour_array(new_tour)
                else # wenn das schon passiert ist...
                    # ...überprüfen ob die neue tour kürzer ist als die vorherige
                    if calc_tour_time(new_tour) < calc_tour_time(best_tour)
                        best_tour = duplicate_tour_array(new_tour)
                    end
                end
            end
        end
        # .place (reihenfolge) speichern
        best_tour.each_with_index do |order_tour, index|
            order_tour.place = index
        end
        best_tour # return
    end # end insertion_pdp()

    # Insertionalgo für DP
    def insertion_dp(order, driver)

        # load tour vom driver (wenn eine besteht)
        old_tour = []
        # Alle OrderTour Elemente laden und old_tour befüllen
        unless driver.active_tour.nil?
            # sortiert nach place
            driver_tour = driver.active_tour.order_tours
            driver_tour = driver_tour.sort {|x,y| x.place <=> y.place}
            driver_tour.each do |tour_element|
                old_tour.push(tour_element)
            end
        end

        #Wenn es keine alte Tour gab, neue Tour erzeugen
        if old_tour.empty?
            # Tour erzeugen
            driver_tour = Tour.create(driver_id: driver.id, duration: 0)
            # startpostion einfügen
            vehicle_position = create_vehicle_position(driver)
            vehicle_position.tour_id = driver_tour.id
            vehicle_position.place = 0
            vehicle_position.save
            #depot einfügen
            depot = create_depot(vehicle_position)
            depot.tour_id = driver_tour.id
            depot.capacity = driver.vehicle.capacity # Fahrzeug vollbeladen
            depot.place = 1
            depot.save
            # home einfügen - entspricht unternehmensadresse
            home = create_home(depot, driver)
            home.tour_id = driver_tour.id
            home.place = 2
            home.save
            # old_tour befüllen
            old_tour.push(vehicle_position)
            old_tour.push(depot)
            old_tour.push(home)
        end

        # Delivery OrderTour
        order_tour_delivery = create_delivery(order)

        # Array für beste tour
        best_tour = []

        # OrderTour an verschiedenen Positionen einsetzen
        old_tour.each_with_index do |location, index|
            # Abbrechen bevor nach home eingesetzt wird
            if index+2 == old_tour.length
                break
            end
            # index+2 damit erst nach vehicle_position und erstem depot eingesetzt wird

            # Potenziell neue Tour erstellen

            new_tour = duplicate_tour_array(old_tour)

            # Delivery einsetzen
            new_tour.insert(index + 2, order_tour_delivery)

            # OrderTour.time updaten
            new_tour = update_time(new_tour, index+2)

            # Wenn eine Capacity_restriction besteht...
            if company.restriction.capacity_restriction
                # ...Order.capacity_status updaten
                new_tour = update_capacity(new_tour, index+2)
            end

            # Prüfen ob Beschränkungen eingehalten werden
            if check_restriction(new_tour, order, driver)
                break
            end

            # best_tour mit ersten new_tour befüllen
            if best_tour.length < new_tour.length
                best_tour = duplicate_tour_array(new_tour)
            else # wenn das schon passiert ist...
                # ...überprüfen ob die neue tour kürzer ist als die vorherige
                if calc_tour_time(new_tour) < calc_tour_time(best_tour)
                    best_tour = duplicate_tour_array(new_tour)
                end
            end
        end

        # Wenn keine zulässige Tour gebildet werden konnte
        if best_tour.empty?
            # Tour zurückmelden mit langer Fahrzeit, um anzuzeigen, dass keine zulässige gebildet werden konnte
            best_tour.push(OrderTour.new(duration: 100000, time: 10000))
        end
        # .place (Reihenfolge) speichern
        best_tour.each_with_index do |order_tour, index|
            order_tour.place = index
        end

        best_tour # return
    end # end insertion_dp()

    #nicht getestet
    # Insertionalgo für PP
    def insertion_pp(order, driver)
        # load tour vom driver (wenn eine besteht)
        old_tour = []

        # Alle OrderTour Elemente laden und old_tour befüllen
        unless driver.active_tour.nil?
            # sortiert nach place
            driver_tour = driver.tour.order_tours
            driver_tour = driver_tour.sort {|x,y| x.place <=> y.place}
            driver_tour.each do |tour_element|
                old_tour.push(tour_element)
            end
        end

        #Wenn es keine alte Tour gab, neue Tour erzeugen
        if old_tour.empty?
            # Tour erzeugen
            driver_tour = Tour.create(user_id: user.id, company_id: company.id, duration: 0)
            # startpostion einfügen
            vehicle_position = create_vehicle_position(driver)
            vehicle_position.tour_id = driver_tour.id
            vehicle_position.place = 0
            vehicle_position.save
            # home einfügen - entspricht unternehmensadresse
            home = create_home(vehicle_position, driver)
            home.tour_id = driver_tour.id
            home.place = 1
            home.save
            driver.tour = driver_tour
            # old_tour befüllen
            old_tour.push(vehicle_position)
            old_tour.push(home)
        end

        # Pickup OrderTour
        order_tour_pickup = create_pickup(order)

        # OrderTour an verschiedenen Positionen einsetzen
        old_tour.each_with_index do |location, index|
            # Abbrechen bevor nach/zwischen letzten depot und home eingesetzt wird
            if index+1 == old_tour.length
                break
            end

            #potenziell neue Tour erstellen
            new_tour = duplicate_tour_array(old_tour)

            # Pickup einsetzen
            new_tour.insert(index+1, order_tour_pickup)

            # OrderTour.time updaten
            new_tour = update_time(new_tour, index+1)
            # Wenn eine Capacity_restriction besteht...
            if restriction.capacity_restriction
                # ...Order.capacity_status updaten
                new_tour = update_capacity(new_tour, index)
            end

            # Prüfen ob Beschränkungen eingehalten werden
            if check_restriction(new_tour, order, driver)
                break
            end

            # Depot als letztes vor home einsetzen, zum Entladen
            # Bestehendes Depot anpassen .capacity
            # Depot einsetzen
            depot.capacity = old.tour[tour.length-2].capacity_status*-1 # Fahrzeug wird entladen
            old_tour.insert(old_tour.length-2 , depot)
            # Zeit und Kapazität updaten
            update_time(old_tour, tour.length-2)
            update_capacity(old_tour, tour.length-2)
            # best_tour mit ersten new_tour befüllen
            if best_tour.length < new_tour.length
                best_tour = duplicate_tour_array(new_tour)
            else # wenn das schon passiert ist...
                # ...überprüfen ob die neue tour kürzer ist als die vorherige
                if calc_tour_time(new_tour) < calc_tour_time(best_tour)
                    best_tour = duplicate_tour_array(new_tour)
                end
            end
        end
        # .place (reihenfolge) speichern
        best_tour.each_with_index do |order_tour, index|
            order_tour.place = index
        end
        tour # return
    end # end insertion_pp()

    #Orders in Gruppen nach den Priorities einteilen
    def by_priority()
        # Array für Sorteriung der Orders nach prio
        prioA=[]
        prioB=[]
        prioC=[]
        prioD=[]
        prioE=[]
        orders.each do |order|
            # Prüfen ob es priorities gibt
            unless order.customer.nil?
            # wenn ja, dann nach der priority sortieren
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
            else# Wenn es kein Prio gibt, dann in D
                prioD.push(order)
            end
        end
        prioArray =[prioA, prioB, prioC, prioD, prioE]
        prioArray # return
    end # end by_priority()

    # erstellt zu order ein ordertour vom typ pickup
    def create_pickup(order)
        order_tour_pickup = OrderTour.new
        # user_id wird in commit gesetzt
        order_tour_pickup.order_id = order.id
        # tour_id wird in commit gesetzt
        # company_id wird in commit gesetzt
        order_tour_pickup.location = order.pickup_location
        # place (Plazierung) wird im algo gesetzt
        order_tour_pickup.comment = order.comment
        order_tour_pickup.kind = "pickup"
        order_tour_pickup.capacity = order.capacity
        # capacity_status (Ladestatus Fahrzeug) wird im algo gesetzt
        # time wird im Algo gesetzt
        order_tour_pickup.duration = order.duration_pickup
        # latitude/longitude werden von Geocoder gesetzt
        order_tour_pickup # return
    end # end create_pickup

    # erstellt zu order ein ordertour vom typ delivery
    def create_delivery(order)
        order_tour_delivery = OrderTour.new
        # user_id wird in commit gesetzt
        order_tour_delivery.order_id = order.id
        # tour_id wird in commit gesetzt
        # company_id wird in commit gesetzt
        order_tour_delivery.location = order.delivery_location
        # place (Plazierung) wird im algo gesetzt
        order_tour_delivery.comment = order.comment
        order_tour_delivery.kind = "delivery"
        # Nur bei Capacity Restriction wichtig
        if company.restriction.capacity_restriction
            order_tour_delivery.capacity = order.capacity*-1 # negativ weil entladen wird
        else
            order_tour_delivery.capacity = 0
        end
        # capacity_status (Ladestatus Fahrzeug) wird im algo gesetzt
        # time wird im Algo gesetzt
        order_tour_delivery.duration = order.duration_delivery
        # latitude/longitude werden von Geocoder gesetzt
        order_tour_delivery # return
    end # end create_delivery

    # erstellt OrderTour für vp driver
    def create_vehicle_position(driver)
        # carrier.vehicle.position einsetzen als OrderTour
        vehicle_position = OrderTour.new
        vehicle_position.order_id = nil
        # tour_id wird in commit gesetzt
        # company_id wird im algo gesetzt
        driver_vehicle = Vehicle.where(driver_id: driver.id).take
        vehicle_position.location = driver_vehicle.position
        # place (Platzierung) wird im commit gesetzt
        vehicle_position.comment = "Start der Tour"
        vehicle_position.kind = "position"
        vehicle_position.capacity = 0
        vehicle_position.capacity_status = 0
        vehicle_position.time = 0 # Keine Zeit vergangen
        vehicle_position.duration = 0 # Keine Zeit benötigt
        # latitude/longitude werden von Geocoder gesetzt
        vehicle_position # return
    end # end create_vehicle_position

    # erstellt OrderTour home für driver
    def create_home(vehicle_position, driver)
        # home = company.address
        home = OrderTour.new
        #home.user_id = user.id
        home.order_id = nil
        # tour_id wird in commit gesetzt
        # company_id wird im algo gesetzt
        home.location = company.address
        # place (Platzierung) wird im commit gesetzt
        home.comment = "Ende der Tour"
        home.kind = "home"
        home.capacity = 0
        # capacity_status (Ladestatus Fahrzeug) wird im algo gesetzt
        home.time = time_for_distance(vehicle_position, home)
        home.duration = 0 # Keine Zeit benötigt
        # latitude/longitude werden von Geocoder gesetzt
        home # return
    end # end create_home

    # erstellt OrderTour depot
    def create_depot(location)
        # depot = company.depot
        depot = OrderTour.new
        depot.order_id = nil
        # tour_id wird in commit gesetzt
        # company_id wird in commit gesetzt
        company_depot = Depot.where(company_id: company.id).take
        depot.location = company_depot.address
        # place wird im algo gesetzt
        depot.comment = "Warenbestand auffüllen"
        depot.kind = "depot"
        # Cpacity wird im Algo gesetzt - Fahrzeug soll voll beladen oder entladen werden
        # capacity_status wird in algo gesetzt
        depot.time = time_for_distance(location, depot)
        depot.duration = company_depot.duration
        # latitude/longitude werden von Geocoder gesetzt
        depot # return
    end # end create_depot()

    # Berechnet die Zeit für die Fahrt von order_tour1 nach order_tour2
    def time_for_distance(ot1, ot2)
        # Google Maps
        dt = DriveTimeBetweenAddresses.new(ot1.location, ot2.location)
        time = dt.cached_drive_time_in_minutes()
        time # return
    end# end time_for_distance()

    # Überprüft für die tour ob die Beschränkungen eingehalten werden
    def check_restriction(tour,order,driver)
        # Check
        if company.restriction.time_window
            if time_window?(tour, order, driver)
                return true
            end
        end

        if company.restriction.capacity_restriction
            if capacity?(tour, driver)
                return true
            end
        end

        if company.restriction.work_time
            if working_time?(tour, driver)
                return true
            end
        end
        false # liefert true, wenn alle Beschränkungen eingehalten werden
    end # end check_restriction()

    #nicht getestet
    # Überprüfen ob Capacity restricion eingehalten wird und setzt ggf. Depots ein
    def capacity?(tour, driver) # liefert true, wenn gegen restriction verstoßen wird
        tour.each_with_index do |order_tour, index|
            # Wenn eine bei einem Punkt in Tour die Capacity überschritten wird
            if order_tour.capacity_status > driver.vehicle.capacity
                if company.restriction == "PP" # Und es ein PP ist,...
                    #... dann soll ein Depot davor eingesetzt werden
                    depot = create_depot()
                    # Fahrzeug komplett entleeren
                    depot.capacity = tour[index-1]*-1
                    # Vor Verstoß einsetzen
                    tour.insert(index-1, depot)
                    # update capacity_status
                    tour = update_capacity(tour, index)
                else
                    return true # Wenn es PDP ist, dann Verstoß
                end
            elsif order_tour.capacity_status <= 0  # oder kleiner, gleich 0 ist
                if company.restriction == "DP" # Und es ein DP ist,...
                    #... dann soll ein Depot davor eingesetzt werden
                    depot = create_depot()
                    # Fahrzeug vollbeladen
                    depot.capacity = driver.capacity - tour[index-1]
                    # Vor Verstoß einsetzen
                    tour.insert(index-1, depot)
                    # Capacity_status updaten
                    tour = update_capacity(tour, index)
                else
                    return true # Wenn es PDP ist, dann Verstoß
                end
            end
        end
        # ...sonst false
        return false
    end # end capacity?()

    #nicht getestet
    # Überprüfen ob Time Windows eingehalten werden
    def time_window?(tour, order, driver) # liefert true, wenn gegen restriction verstoßen wird
        time_now = Time.now.to_time.to_i # Jetziger Zeitpunkt in Unixtime
        # Jede Order_tour überprüfen, ob der Zeitpunkt im Zeitfenster von Order ist
        tour.each_with_index do |order_tour, index|
            # Zeit bis zu Order_tour
            tour_until = tour[0..index]
            time_until = calc_tour_time(tour_until)
            # time_now plus Zeit bis Order_time
            time_point = time_now + time_until
            # time_point nach end_time oder vor starttime
            if time_point > order_tour.order.end_time || time_point < order_tour.order.start_time
                return true
            end
        end
        return false
    end

    # Überprüfen ob working time eingehalten wird
    # Kann dazu führen, kann das keine Tour gebildet wird! Passiert vor allem bei nur einem Fahrer
    def working_time?(tour, driver) # liefert true, wenn gegen restriction verstoßen wird
        # Prüfen ob die Tourdauer > als working_time vom Driver
        if calc_tour_time(tour) > driver.working_time
            # true wenn tour zu lang ist
            return true
        end
        false
    end # end working_time?()

    # Berechnet OrderTour.time neu
    def update_time(tour, index)
        # OrderTour.time setzen
        tour[index].time = time_for_distance(tour[index-1], tour[index])
        #... und das nächste Element
        tour[index+1].time = time_for_distance(tour[index], tour[index+1])
        tour # return
    end

    #nicht getestet
    # Berechnet OrderTour.capacity_status neu für alle OrderTours ab index
    def update_capacity(tour, index)
        tour(index).capacity_status = tour(index-1).capacity_status + tour(index).capacity
        # OrderTour.capacity_status für alle Nachfolgenden setzen
        tour.each_with_index do |order_tour, index2|
            # erst nach neuem element updaten
            if index2 > index
                order_tour.capacity_status = new_tour(index2-1).capacity_status + new_tour(index2).capacity
            end
        end
        tour # return
    end

    # erzeugt echte Copy von Array
    def duplicate_tour_array (tour)
        new_tour = []
        tour.each do |element|
            new_tour.push(element.clone)
        end
        new_tour
    end# end duplicate_tour_array()

    # gibt die Zeit für die gesamte Tour zurück
    def calc_tour_time(tour)
        tour_time = 0
        # ungespeichertes Tour.arry
        if tour.kind_of?(Array)
            tour.each do |order_tour|
                tour_time += order_tour.time # Fahrzeit
                if order_tour.duration # Manche Aufträge haben ggf. keine Arbeitszeit
                    tour_time += order_tour.duration # Arbeitszeit
                end
            end
        else # gespeicherte Tour Relation
            tour.order_tours.each do |order_tour|
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
        tour_time # return
    end# end calc_tour_time()

end
