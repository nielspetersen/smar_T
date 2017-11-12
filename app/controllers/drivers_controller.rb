class DriversController < ApplicationController
  before_action :set_driver, only: [:show, :edit, :update, :destroy]

  respond_to :html

  def index
    if (current_user.is_admin? || current_user.is_planer? || (current_user.is_superadmin? && current_user.company_id?)) && !current_user.company.nil?
      company = current_user.company
      @drivers = company.drivers
    else
      @drivers = []
    end
  end

  def show
      if current_user.is_admin? || (current_user.is_superadmin? && current_user.company_id?)
        if @driver.user.company_id == current_user.company_id
          @driver
        end
      end
  end


  def new
    if current_user
      if current_user.is_admin? || current_user.is_planer? || (current_user.is_superadmin? && current_user.company_id?)
        @driver = Driver.new
        @driver.active = true
      end
    end
  end

  def edit
   @driver.intToTime
    # FIXME
  end

  def create
    @driver = Driver.new(driver_params)
    @driver.timeToInt
    if @driver.save
      flash[:success] = t('.success', name: @driver.name)
      redirect_to drivers_path
    else
      flash[:alert] = t('.failure')
      render 'new'
    end
  end

  def update
    if @driver.update(driver_params)
      flash[:success] = t('.success', name: @driver.name)
    respond_with(@driver)
    else
      flash[:alert] = t('.failure', name: @driver.name)
      render("edit")
    end
  end

  def destroy
    if @driver.destroy
        flash[:success] = t('.success', name: @driver.name)
    respond_with(@driver)
    else
      flash[:alert] = t('.failure', name: @driver.name)
      respond_with(@driver)
    end
  end

  private
    def set_driver
      @driver = Driver.find(params[:id])
    end

    def driver_params
      params.require(:driver).permit(:user_id, :name, :work_start_time, :work_end_time, :active, :working_time, :hour, :minute)
    end
end
