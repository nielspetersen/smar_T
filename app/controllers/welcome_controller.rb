class WelcomeController < ApplicationController
  skip_before_action :authenticate_user!, only: :index

  def index
    if current_user && current_user.is_driver?
      @tour =  Tour.where(driver_id: current_user.id).take
    elsif current_user && current_user.is_planer?
      if current_user.company
        @drivers = current_user.company.drivers
        @hash = Gmaps4rails.build_markers(@drivers) do |driver, marker|
          unless driver.vehicle.nil?
            marker.lat driver.vehicle.latitude
            marker.lng driver.vehicle.longitude
          end
        end
      end
    end
  end
end
