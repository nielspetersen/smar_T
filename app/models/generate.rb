#Klasse zur Erstellung der Touren entsprechen der Konfiguration

#Ideas : durch OrderTour.time kann man herausfinden wie lange man von der vorherigen location zu dieser braucht. Dadruch weniger anfragen an Maps,
# denn man muss für jede Einsetzung nur die time vom eignen und nächsten location updaten und die nummerirung aller nachfolgenden orderTour +1

class Generate
    
    #Variablen
    attr_accessor :drivers, :orders, :company, :user
    # Depot und home können aus dem Kontext abgeleitet werden
    
    #Methoden
    #TESTED
    # generiete die Touren für alle driver und orders entsprechend der company.restriction
    def generate_tours()
        # Prüfen ob Prioritätsstufen bestehen
        if company.restriction.priorities
            # orders ändern zu array von arrays, für jede priority eine array
            orders_array = by_priority()
            # Jedes order in orders nacheiander lösen
            orders_array.each do |prio_orders|
                orders = prio_orders
                order_count = orders.length
                # Matrix für jede Prioritässtufe
                matrix = build_matrix()
                # jede Prioritätsstufe nacheinander bearbeiten
                solve_matrix(matrix, order_count)
            end
        else # keine Prioritätsstufen
            # Matrix zwischen allen Drivern und allen Orders aufspannen
            matrix = build_matrix()
            order_count = orders.length
            # Alle Orders in Matrix zuteilen 
            solve_matrix(matrix, order_count)
        end
        # Touren generiert
    end # end generate_tour()
    
    #TESTED
    # Matrix für Drivers und Orders
    def build_matrix()
        matrix = []
        # MV oder SV wird automatisch durch die Anzahl von Drivern in Drivers beachtet
        # für jede Order...
        orders.each do |order|
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
    
    # DONE
    # MMM durchführen
    def solve_matrix(matrix, order_count)
        # für jeder Order eine Tour finden
        i = 0
        while  i < order_count
            shortest_tour = matrix[0] # erste tour als shortest_tour
            # schnellste Tour ermitteln
            matrix.each do |possible_tour|
                # tour ist im dritten element [2] von possible_tour
                duration_shortest_tour = calc_tour_time(shortest_tour[2])
                duration_tour = calc_tour_time(possible_tour[2])
                # Wenn tour kürzer ist...
                if duration_shortest_tour > duration_tour 
                    shortest_tour = possible_tour # ...dann ist die possible_tour die neue shortest_tour
                end
            end
            # leserlich umspeichern
            driver = shortest_tour[0]
            order = shortest_tour[1]
            tour = shortest_tour[2]
            # Driver die Tour (samt neuer Order) zuteilen
            commit_order(driver, tour, order)
            #update matrix - Löschen aller Einträge mit der Order und die Zeiten vom Fahrer updaten
            matrix = update_matrix(matrix, driver, order)
            i += 1
        end
    end
    
    # FIXME - die touren in der matrix werden nicht upgedated
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
        
        # Einträge mit der Order löschen
        matrix.each_with_index do |tour, index|
            # Alle Einträge von Driver updaten
            if tour[0].id == driver.id # Driver steht in tour[0]
                # Tour neuberechnen
                tour[2] = build_tour(tour[1], tour[0]) 
            end
        end
        matrix # return
    end # end update_matrix()
    
    #DONE
    # Erstellt die OrderTour objekte und speichert die neue Tour und OrderTour in der DB
    def commit_order(driver, tour, order)
        #Alte tour suchen und ggf. löschen, sowie die OrderTours davon
        if Tour.where(driver_id: driver.id).exists?
             original_tour = Tour.where(driver_id: driver.id).take
            #OrderTours der Tour löschen
            OrderTour.where(tour_id: original_tour.id).find_each do |order_tour|
               order_tour.destroy
           end
            # Tour löschen
           original_tour.destroy
        end
        
        # neue Tour erstellen
        new_tour= Tour.create(user_id: user.id, driver_id: driver.id, company_id: company.id, duration: 0)
        # fehlende Attribute setzen und mit new_tour verbinden
        tour.each_with_index do |order_tour, index|
            if order_tour.duration.nil?
                order_tour.duration = 0
            end
            OrderTour.create(user_id: user.id, tour_id: new_tour.id, company_id: company.id, location: order_tour.location, place: index, comment: order_tour.comment, capacity: order_tour.capacity, capacity_status: order_tour.capacity_status, time: order_tour.time, duration: order_tour.duration, kind: order_tour.kind)
        end
        # Duration setzen
        new_tour.duration = calc_tour_time(tour)
        # Tour mit Driver verbinden
        new_tour.driver_id = driver.id  
        new_tour.save
        driver.tour = new_tour
        # Order deaktivieren, damit sie in nächsten Planungen nicht versehentlich verplant wird
        # FIXME - wieder einkommentieren
        #order.activ = false
        #order.save
    end # end commit_order()
    
    #DONE
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
    
    # Not Tested
    # Insertionalgo für PDP
    def insertion_pdp(order, driver)
        # load tour vom driver (wenn eine besteht)
        old_tour = []
        # Alle OrderTour Elemente laden und old_tour befüllen
        unless Tour.where(driver_id: driver.id).nil?
            driver.tour.order_tours.each do |tour_element|
                old_tour.push(tour_element)
            end
        end
        
        #Wenn es keine alte Tour gab, neue Tour vorbereiten
        if old_tour.empty?
            # startpostion einfügen
            vehicle_position = create_vehicle_position(driver)
            old_tour.push(vehicle_position)
            # home einfügen - entspricht unternehmensadresse
            home = create_home(vehicle_position, driver)
            old_tour.push(home)
        end
        
        # Order in zwei OrderTours zerlegen
        # Pickup OrderTour 
        order_tour_pickup = create_pickup(order)
        # Delivery OrderTour
        order_tour_delivery = create_delivery(order)
        # Array für beste tour
        best_tour = []
        
        # OrderTours an verschiedenen Positionen von old_tour einsetzen
        old_tour.each_with_index do |location_first, index_first|
            # Abbrechen bevor nach home eingesetzt wird
            if index_first+1 == new_tour.length
                break
            end
            #potenziell neue Tour erstellen
            new_tour = duplicate_tour_array(old_tour)
            
            # Pickup einsetzen
            new_tour.insert(index_first+1, order_tour_pickup)
            # OrderTour.time updaten
            new_tour = update_time(new_tour, index_first)
            # Wenn eine Capacity_restriction besteht...
            if restriction.capacity_restriction
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
        best_tour # return
    end # end insertion_pdp()
    
    # Not tested
    #Insertionalgo für DP
    def insertion_dp(order, driver)
        # load tour vom driver (wenn eine besteht)
        old_tour = []
        
        # Alle OrderTour Elemente laden und old_tour befüllen
        unless driver.tour.nil?
            driver.tour.order_tours.each do |tour_element|
                old_tour.push(tour_element)
            end
        end
        
        #Wenn es keine alte Tour gab, neue Tour vorbereiten
        if old_tour.empty?
            # startpostion einfügen
            vehicle_position = create_vehicle_position(driver)
            old_tour.push(vehicle_position)
            # Depot einsetzen - zum Beladen des Fahrzeuges
            depot = create_depot()
            driver_vehicle = Vehicle.where(driver_id: driver.id).take
            depot.capacity = driver_vehicle.capacity # Fahrzeug wird voll beladen
            old_tour.push(depot)
            # home einfügen - entspricht unternehmensadresse
            home = create_home(vehicle_position, driver)
            old_tour.push(home)
            update_time(old_tour, 1) # .time von depot und home setzen
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
            new_tour.insert(index+2, order_tour_delivery)

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
        best_tour # return
    end # end insertion_dp()
    
    # Not tested
    #Insertionalgo für PP
    def insertion_pp(order, driver)
        # load tour vom driver (wenn eine besteht)
        old_tour = []
        # Alle OrderTour Elemente laden und old_tour befüllen
        unless driver.tour.nil?
            driver.tour.order_tours.each do |tour_element|
                old_tour.push(tour_element)
            end
        end
        
        #Wenn es keine alte Tour gab, neue Tour vorbereiten
        if old_tour.empty?
            # startpostion einfügen
            vehicle_position = create_vehicle_position(driver)
            old_tour.push(vehicle_position)
            # home einfügen - entspricht unternehmensadresse
            home = create_home(vehicle_position, driver)
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
            depot = create_depot()
            depot.capacity = old.tour[tour.length-2].capacity_status*-1 # Fahrzeug wird entladen
            old_tour.insert(old_tour.length-2 , depot)
            update_time(old_tour, tour.length-2) # .time depot und home setzen
            # FIXME -> capcity und time updaten
                
        end
        tour # return
    end # end insertion_pp()
    
    #DONE
    #Orders in Gruppen nach den Priorities einteilen
    def by_priority()
        prioA=[]
        prioB=[]
        prioC=[]
        prioD=[]
        orders.each do |order|
            if order.costumer.priority = "A"
                prioA.push(order)
            elsif order.costumer.priority = "B"
                prioB.push(order)
            elsif order.costumer.priority = "C"
                prioC.push(order)
            else # Prio "D" oder null oder Eingabefehler
            # FIXME - sagt immmer "A" obwohl prio ganz klar "D"
                prioD.push(order)
            end
        end
        prioArray =[prioA, prioB, prioC, prioD]
        prioArray # return
    end # end by_priority()
    
    #DONE
    # erstellt zu order ein ordertour vom typ pickup
    def create_pickup(order)
        order_tour_pickup = OrderTour.new
        # user_id wird in commit gesetzt
        order_tour_pickup.order_id = order.id
        # tour_id wird in commit gesetzt
        # company_id wird in commit gesetzt
        order_tour_pickup.location = order.pickup_location
        # place (Plazierung) wird im commit gesetzt
        order_tour_pickup.comment = order.comment
        order_tour_pickup.kind = "pickup"
        order_tour_pickup.capacity = order.capacity
        # capacity_status (Ladestatus Fahrzeug) wird im algo gesetzt
        # time wird im Algo gesetzt
        order_tour_pickup.duration = order.duration_pickup
        # latitude/longitude werden von Geocoder gesetzt
        order_tour_pickup # return
    end # end create_pickup
    
    #DONE
    # erstellt zu order ein ordertour vom typ delivery
    def create_delivery(order)
        order_tour_delivery = OrderTour.new
        # user_id wird in commit gesetzt
        order_tour_delivery.order_id = order.id
        # tour_id wird in commit gesetzt
        # company_id wird in commit gesetzt
        order_tour_delivery.location = order.delivery_location
        # place (Plazierung) wird im commit gesetzt
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
    
    # DONE
    # erstellt OrderTour für vp driver
    def create_vehicle_position(driver)    
        # carrier.vehicle.position einsetzen als OrderTour
        vehicle_position = OrderTour.new
        # user_id wird in commit gesetzt
        vehicle_position.order_id = nil
        # tour_id wird in commit gesetzt
        # company_id wird in commit gesetzt
        driver_vehicle = Vehicle.where(driver_id: driver.id).take
        vehicle_position.location = driver_vehicle.position
        # place (Platzierung) wird im commit gesetzt
        vehicle_position.comment = nil
        vehicle_position.kind = "position"
        vehicle_position.capacity = 0
        vehicle_position.capacity_status = 0
        vehicle_position.time = 0 # Keine Zeit vergangen
        vehicle_position.duration = 0 # Keine Zeit benötigt
        # latitude/longitude werden von Geocoder gesetzt
        vehicle_position # return
    end # end create_vehicle_position
    
    # DONE
    # erstellt OrderTour home für driver
    def create_home(vehicle_position, driver)
        # home = company.address
        home = OrderTour.new
        # user_id wird in commit gesetzt
        home.order_id = nil
        # tour_id wird in commit gesetzt
        # company_id wird in commit gesetzt
        driver_vehicle = Vehicle.where(driver_id: driver.id).take
        home.location = driver_vehicle.position
        # place (Platzierung) wird im commit gesetzt
        home.comment = nil
        home.kind = "home"
        home.capacity = 0
        # capacity_status (Ladestatus Fahrzeug) wird im algo gesetzt
        home.time = time_for_distance(vehicle_position, home)
        home.duration = 0 # Keine Zeit benötigt
        # latitude/longitude werden von Geocoder gesetzt
        home # return
    end # end create_home
    
    # DONE
    # erstellt OrderTour depot
    def create_depot()
        # depot = company.depot
        depot = OrderTour.new
        # user_id wird in commit gesetzt
        depot.order_id = nil
        # tour_id wird in commit gesetzt
        # company_id wird in commit gesetzt
        company_depot = Depot.where(company_id: company.id).take
        depot.location = company_depot.address
        # place wird in commit gesetzt
        depot.comment = "Warenbestand auffüllen"
        depot.kind = "depot"
        # Cpacity wird im Algo gesetzt - Fahrzeug soll voll beladen oder entladen werden
        # capacity_status wird in algo gesetzt
        # time wird im Algo gesetzt
        depot.duration = company_depot.duration
        # latitude/longitude werden von Geocoder gesetzt
        depot # return
    end # end create_depot()
    
    #Tested
    # Berechnet die Zeit für die Fahrt von order_tour1 nach order_tour2
    def time_for_distance(ot1, ot2)
        # Google Maps - Echte Farhezit - Anfrangen beschränkt
        # FIXME - liefert abn und zu 0 zurück!
        directions = GoogleDirections.new(ot1.location, ot2.location)
        directions.drive_time_in_minutes
        # Geocoder - Distanze in km
        #if ot1.latitude.nil?
        #    geocords = Geocoder.search(ot1.location) 
        #    ot1.latitude = geocords[1].boundingbox[0]
        #    ot1.longitude = geocords[1].boundingbox[2]
        #end
        #if ot2.latitude.nil?
        #    geocords = Geocoder.search(ot2.location) 
        #    ot2.latitude = geocords[0].boundingbox[0]
        #    ot2.longitude = geocords[0].boundingbox[2]
        #end
        #Geocoder::Calculations.distance_between([ot1.latitude,ot1.longitude], [ot2.latitude,ot2.longitude])
    end# end time_for_distance()
    
    # DONE
    # Überprüft für die tour ob die Beschränkungen eingehalten werden
    def check_restriction(tour,order,driver)
        # Check
        if company.restriction.time_window
            if time_window?(tour, order, driver)
                return true
            end
        end
        
        #FIXME Depots einfügen
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
    
    # Not tested
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
    
    #FIXME - Warten um eine Order einsetzen zu können
    # Überprüfen ob Time Windows eingehalten werden
    def time_window?(tour, order, driver) # liefert true, wenn gegen restriction verstoßen wird
        # Uhrzeit von jetzt bis OrderTour von Order prüfen
        # Wenn die Uhrzeit < order.start_time
        # return true -> Pickup ist zu früh
        # Wenn PDP
        # Prüfen ob der Delivery nach order.end_time ist
        # return true -> Delivery ist zu spät
        
                    
        # wenn durch time_window keine zulässige Tour gebildet werden konnte
        # dann an die matrix eintragen, dass es nicht geht durch sehr lange duration
            
    end
    
    #DONE
    # Überprüfen ob working time eingehalten wird
    def working_time?(tour, driver) # liefert true, wenn gegen restriction verstoßen wird
        # Prüfen ob die Tourdauer > als working_time vom Driver
        if calc_tour_time(tour) > driver.working_time
            # true wenn tour zu lang ist
            return true
        end
        return false
    end # end working_time?()
    
    #DONE
    # Berechnet OrderTour.time neu
    def update_time(tour, index)
        # OrderTour.time setzen
        tour[index].time = time_for_distance(tour[index-1], tour[index])
        #... und das nächste Element
        tour[index+1].time = time_for_distance(tour[index], tour[index+1])
        
        tour # return
    end
    
    #DONE
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
    
    #DONE
    # erzeugt echte Copy von Array
    def duplicate_tour_array (tour)
        new_tour = []
        tour.each do |element|
            new_tour.push(element.clone)
        end
        new_tour
    end# end duplicate_tour_array()
    
    #DONE
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
            end
        end

        tour_time # return
    end# end calc_tour_time()
end