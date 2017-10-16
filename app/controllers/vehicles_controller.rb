class VehiclesController < ApplicationController
  before_action :set_vehicle, only: [:show, :edit, :update, :destroy]

  respond_to :html

  def index
    if (current_user.is_admin? || current_user.is_planer? || (current_user.is_superadmin? && current_user.company_id?)) && !current_user.company.nil?
      company = current_user.company
      @vehicles = company.vehicles
    else
      @vehicles = []
    end
  end

  def show
    respond_with(@vehicle)
  end

  def new
    if current_user
      if current_user.is_admin? || (current_user.is_superadmin? && current_user.company_id?) || current_user.company_id
        @vehicle = Vehicle.new
      end
    end
  end

  def edit
    # FIXME
  end

  def create
    @vehicle = Vehicle.new(vehicle_params)
    @vehicle.company_id = current_user.company.id
    if @vehicle.save
      flash[:success] = t('.success', vehicle_id: @vehicle.id)
    respond_with(@vehicle)
      else
      flash[:alert] = t('.failure')
      render 'new'
    end
  end

  def update
    if @vehicle.update(vehicle_params)
      flash[:success] = t('.success', vehicle_id: @vehicle.id)
    respond_with(@vehicle)
      else
      flash[:alert] = t('.failure', vehicle_id: @vehicle.id)
      render("edit")
    end
  end

  def destroy
    if @vehicle.destroy
      flash[:success] = t('.success', vehicle_id: @vehicle.id)
    respond_with(@vehicle)
    else
     flash[:alert] = t('.failure', vehicle_id: @vehicle.id)
     respond_with(@vehicle)
    end
  end

  private
    def set_vehicle
      @vehicle = Vehicle.find(params[:id])
    end

    def vehicle_params
      params.require(:vehicle).permit(:user_id, :position, :capacity, :duration, :driver_id, :model, :registration_number, :manufacturer)
    end
end
