class ToursController < ApplicationController
  include OrderToursHelper
  before_action :set_tour, only: [:show, :edit, :update, :destroy, :print, :start, :complete, :finish]

  respond_to :html

  def index
    # Nur Daten die Zur Rolle passen anzeigen
    @tours = []
    tour_filter = filter_tour_params.reject{|_, v| v.blank?}
    if (current_user.is_admin? || current_user.is_planer? || (current_user.is_superadmin? && current_user.company_id?)) && !current_user.company.nil?
      @tours = current_user.company.approved_tours(tour_filter).page params[:page]
    elsif current_user.is_driver?
      if current_user.try(:driver).try(:has_tours?)
        @tours = current_user.driver.approved_tours(tour_filter).page params[:page]
      end
    end
    @tours
  end

  def show
    if current_user.is_admin? || (current_user.is_superadmin? && current_user.company_id?)
      @order_tours = @tour.order_tours.sort_by &:place
      @hash = @order_tours.map do | order_tour|
        place = order_tour.place+1
        {latitude: order_tour.latitude, longitude: order_tour.longitude, place: place.to_s}
      end
    elsif current_user.is_planer? || current_user.is_driver?
      if @tour.driver.company == current_user.company
        @order_tours = @tour.order_tours.sort_by &:place
        @hash = @order_tours.map do | order_tour|
          place = order_tour.place+1
          {latitude: order_tour.latitude, longitude: order_tour.longitude, place: place.to_s}
        end
      end
    end
    respond_with(@tour, @hash)
  end

  def new
    #Ausgabe nach Rolle filtern
    if current_user.is_admin? || current_user.is_planer? || (current_user.is_superadmin? && current_user.company_id?)
      if current_user.company
        if current_user.company.google_maps_api_key.blank?
          flash[:error] = t('.no_google_maps_api_key_assigned')
        else
          order_type_filter = preprocess_order_type_params(new_tour_params)
          if order_type_filter
            Algorithm::TourGeneration.generate_tours(current_user.company, order_type_filter)
          else
            flash[:warning] = t('.no_order_type_selected')
          end
        end
      else
        flash[:error] = t('.no_company_assigned')
      end
      @tours = current_user.company.approved_tours
      redirect_to action: 'index'
    end
  end

  def edit
    #FIXME pause, start, done funktionen einfügen
  end

  def create
    @tour = Tour.new(tour_params)
    if @tour.save
        flash[:success] = t('.success')
    respond_with(@tour)
      else
      flash[:alert] = t('.failure')
      render 'new'
    end
  end

  def update
    if @tour.update(tour_params)
        flash[:success] = t('.success')
    respond_with(@tour)
      else
        flash[:alert] = t('.failure')
        render("edit")
    end
  end

  def destroy
    # Alle OrderTours von @tour löschen
    order_tours = @tour.order_tours
    order_tours.each do |order_tour|
      order_tour.destroy
    end
    if @tour.destroy
      flash[:success] = t('.success')
      respond_with(@tour)
    else
      flash[:alert] = t('.failure')
      respond_with(@tour)
    end
  end

  def print
    if @tour
      @order_tours = @tour.order_tours
      respond_to do |format|
        format.html
        format.pdf do
          render pdf: "tour_#{params[:id]}",
                 template: 'tours/print.pdf.erb',
                 layout: 'pdf.html'
        end
      end
    else
      redirect_to action: 'index'
    end
  end

  def start
    unless @tour
      redirect_to action: 'index'
    end
    @tour.update_attributes(status: StatusEnum::STARTED, started_at: DateTime.now)
    redirect_to action: 'show'
  end

  def complete
    unless @tour
      redirect_to action: 'index'
    end
    # avoid submitting order_tours for vehicle position, home, etc.
    @order_tours = @tour.order_tours.where(kind: available_order_tour_types())
  end

  def finish
    unless @tour
      redirect_to action: 'index'
    end
    tour_complete_params = finish_tour_params.reject{|_, v| v.blank? }
    begin
      @tour.update_attributes!(status: StatusEnum::COMPLETED, completed_at: DateTime.now)
      order_tours = @tour.order_tours.where(kind: available_order_tour_types())
      if tour_complete_params[:order_ids].blank?
        # no order has been completed
        order_tours.each do |order_tour|
          # remove incomplete orders from completed tour
          reset_order_to_active(order_tour)
        end
      else
        order_tours.each do |order_tour|
          if tour_complete_params[:order_ids].include? order_tour.order_id.to_s
            order = Order.find(order_tour.order_id)
            if order
              order.update_attributes!(status: OrderStatusEnum::COMPLETED)
            end
          else
            # remove incomplete orders from completed tour
            reset_order_to_active(order_tour)
          end
        end
      end
      @tour.update_place_order_tours()

      flash[:success] = t('.success', tour_id: @tour.id)
    rescue ActiveRecord::ActiveRecordError => e
      flash[:alert] = t('.failure')
    end
    redirect_to action: 'index'
  end

  private
    def set_tour
      @tour = Tour.find(params[:id])
    end

    def tour_params
      params.require(:tour).permit(:user_id, :driver_id, :company_id, :duration)
    end

    def new_tour_params
      params.permit(:order_type_delivery, :order_type_pickup, :order_type_service)
    end

    def filter_tour_params
      params.permit(:status)
    end

    def finish_tour_params
      params.permit(:id, order_ids: [])
    end

    def preprocess_order_type_params(params)
      params.reject{|_, v| v.blank? }
      order_type_params = []
      params.each do |key, value|
        case key
          when "order_type_delivery"
            order_type_params.push(OrderTypeEnum::DELIVERY) if value == "1"
          when "order_type_pickup"
            order_type_params.push(OrderTypeEnum::PICKUP) if value == "1"
          when "order_type_service"
            order_type_params.push(OrderTypeEnum::SERVICE) if value == "1"
        end
      end
      unless order_type_params.empty?
        {order_type: order_type_params}
      end
    end

    def reset_order_to_active(order_tour)
      order = Order.find(order_tour.order_id)
      if order
        order.update_attributes!(status: OrderStatusEnum::ACTIVE)
      end
      order_tour.destroy
    end
end
