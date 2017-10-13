class DepotsController < ApplicationController
  before_action :set_depot, only: [:show, :edit, :update, :destroy]

  respond_to :html

  def index
    if (current_user.is_admin? || current_user.is_superadmin?) && current_user.company_id?
      @depots = Depot.where(company_id: current_user.company.id)
    end
  end

  def show
    if (current_user.is_admin? || current_user.is_superadmin?) && current_user.company_id?
      if @depot.company_id == current_user.company_id
        @depot
      end
    end
  end

  def new
    if (current_user.is_admin? || current_user.is_superadmin?) && current_user.company_id?
      @depot = Depot.new
    end
  end

  def edit
  end

  def create
    @depot = Depot.new(depot_params)
    @depot.company_id = current_user.company.id
    if @depot.save
      flash[:success] = t('.success', depot_id: @depot.id)
      respond_with(@depot)
    else
      flash[:alert] = t('.failure')
      render 'new'
    end
  end

  def update
    if @depot.update(depot_params)
      flash[:success] = t('.success', depot_id: @depot.id)
      respond_with(@depot)
    else
      flash[:alert] = t('.failure', depot_id: @depot.id)
      render("edit")
    end
  end

  def destroy
    if @depot.destroy
      flash[:success] = t('.success', depot_id: @depot.id)
      respond_with(@depot)
    else
      flash[:alert] = t('.success', depot_id: @depot.id)
     respond_with(@depot)
    end
  end

  private
    def set_depot
      @depot = Depot.find(params[:id])
    end

    def depot_params
      params.require(:depot).permit(:user_id, :name, :company_id, :address, :duration)
    end
end
