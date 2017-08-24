class ToursController < ApplicationController
  before_action :set_tour, only: [:show, :edit, :update, :destroy]

  respond_to :html

  def index
    # Nur Daten die Zur Rolle passen anzeigen
    if (current_user.is_admin? || current_user.is_planer?) && !current_user.company.nil?
      @tours = current_user.company.tours
    elsif current_user.is_driver?
      @tours = current_user.company.tours
    else
      @tours = []
    end
  end

  def show
    if current_user
      if current_user.is_admin?
        @order_tours = @tour.order_tours.sort_by &:place
        @hash = @order_tours.map do | order_tour|
          place = order_tour.place+1
          {latitude: order_tour.latitude, longitude: order_tour.longitude, place: place.to_s}
        end
      elsif current_user.is_planer?
        if @tour.company_id == current_user.company_id
          @order_tours = @tour.order_tours.sort_by &:place
          @hash = @order_tours.map do | order_tour|
            place = order_tour.place+1
            {latitude: order_tour.latitude, longitude: order_tour.longitude, place: place.to_s}
          end
        end
      end
      respond_with(@tour, @hash)
    end
  end

  def new
    #Ausgabe nach Rolle filtern
    if current_user.is_admin? || current_user.is_planer?
      if current_user.company
        Algorithm::TourGeneration.generate_tours(current_user.company)
        @tours = current_user.company.tours
      else
        flash[:error] = t('.no_company_assigned')
      end
      redirect_to action: 'index'
    end
  end

  def edit
    #FIXME pause, start, done funktionen einfügen
  end

  def create
    @tour = Tour.new(tour_params)
    if @tour.save
        flash[:success] = t('.success', tour_id: @tour.id)
    respond_with(@tour)
      else
      flash[:alert] = t('.failure')
    end
  end

  def update
    if @tour.update(tour_params)
        flash[:success] = t('.success', tour_id: @tour.id)
    respond_with(@tour)
      else
        flash[:alert] = t('.failure', tour_id: @tour.id)
    end
  end

  def destroy
    # Alle OrderTours von @tour löschen
    order_tours = @tour.order_tours
    order_tours.each do |order_tour|
      order_tour.destroy
    end
    if @tour.destroy
      flash[:success] = t('.success', tour_id: @tour.id)
    respond_with(@tour)
      else
      flash[:alert] = t('.failure', tour_id: @tour.id)
    end
  end

  private
    def set_tour
      @tour = Tour.find(params[:id])
    end

    def tour_params
      params.require(:tour).permit(:user_id, :driver_id, :company_id, :duration)
    end
end
