class Company < ActiveRecord::Base
    has_many :users, dependent: :destroy
    has_many :customers, dependent: :destroy
    has_one :restriction, dependent: :destroy
    has_many :depots, dependent: :destroy
    has_many :vehicles, dependent: :destroy

    has_attached_file :logo, styles: { medium: "300x300>", thumb: "100x100>" }
    validates_attachment_content_type :logo, content_type: /\Aimage\/.*\z/
    validates_attachment_file_name :logo, matches: [/png\z/, /jpe?g\z/]
    validates_with AttachmentSizeValidator, attributes: :logo, less_than_or_equal_to: 3.megabytes

    validates :name, presence: {message: "Dieses Feld muss ausgefüllt werden."}
    validates :address, presence: {message: "Dieses Feld muss ausgefüllt werden."}
    validates :email, presence: {message: "Dieses Feld muss ausgefüllt werden."}
    validates :email, uniqueness: {message: "Diese E-Mail ist bereits vergeben."}
   
    # Koordinaten aus Adresse
    geocoded_by :address
    after_validation :geocode

    # Gibt alle Driver zurück, die der Company indirekt über zugewiesene User angehören.
    def drivers
      Driver.where(user_id: self.users.ids)
    end

    def available_drivers
      # retrieve array of all active drivers for company
      active_drivers = Driver.where(user_id: self.users.ids, active: true).to_a
      available_drivers = []
      active_drivers.each do |driver|
        if Vehicle.exists?(driver: driver) && driver.active_tour(nil, [StatusEnum::APPROVED, StatusEnum::STARTED]).blank?
          # only add drivers with vehicle and no conflicting / active tour
          available_drivers.push(driver)
        end
      end
      available_drivers
    end

    # Gibt alle Orders zurück, die der Company indirekt über zugewiesene Customer angehören.
    def orders(select = {})
      where_clause = {customer_id: self.customers.ids}.merge(select)
      Order.where(where_clause)
    end

    # Gibt alle Tours zurück, die der Company indirekt über zugewiesene Customer angehören.
    def tours(select = {})
      where_clause = {driver_id: self.drivers.ids}.merge(select)
      Tour.where(where_clause)
    end

    def approved_tours(select = {})
      # Remove status query parameter if user tries to access tours with no approval
      if select[:status] && select[:status] == StatusEnum::GENERATED
        select.delete(:status)
      end
      self.tours(select)
    end

    # Returns true if time window restriction exists for this company
    def time_window_restriction?
      self.try(:restriction).try(:time_window) ? true : false
    end

    # Returns true if capacity restriction exists for this company
    def capacity_restriction?
      self.try(:restriction).try(:capacity_restriction) ? true : false
    end

    # Returns true if work time restriction exists for this company
    def work_time_restriction?
      self.try(:restriction).try(:work_time) ? true : false
    end
end
