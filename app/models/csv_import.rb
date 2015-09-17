class CsvImport
    
    attr_accessor :file_path
    
    def initialize(folder)
        self.file_path = "#{Rails.root}/tmp/csv/#{folder}"
    end
    
    # import aus csv. vom typ delivery aus dem zuvor mitgegebenen folder
    def import_delivery_orders(company)
        # alle .csv files laden
        get_all_files().each do |file|
            # Trennen am Semikolon und zu array aufbereiten
            CSV.foreach(file, col_sep: ";") do |row|
                # neue Order anlegen
                order = Order.new
                # Mit company verknüpfen
                order.company_id = Company.where(name: company).take.id
                order.delivery_location = row[1] +', '+row[2]
                order.duration_delivery = row[5]
                order.capacity = 0
                order.comment = "Medikamente abliefern!"
                order.activ = true
                order.save!
            end
        end
        # laden aller csv im ordner
        # iterrieren über element und gleichzeitiges schreiben der order
        # überprüfen, das keine Order doppelt ist (manche Zeitfenster enthalten gleiche oder ähnliche orders)
        
    end
    
    # import aus csv. vom typ pickup aus dem zuvor mitgegebenen folder
    def import_pickup_orders(company)
        
    end
    
    # import aus csv. vom typ php aus dem zuvor mitgegebenen folder
    def import_php_orders(company)
        
    end
    
    # Alle files aus folder einlesen
    def get_all_files()
        Dir[file_path + "/*"]# return of array
    end
    
    
end