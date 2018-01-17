class OrdersController < ApplicationController
  include OrdersHelper
  before_action :set_order, only: [:show, :edit, :update, :destroy]

  respond_to :html

  def index
    if (current_user.is_admin? || current_user.is_planer? || (current_user.is_superadmin? && current_user.company_id?)) && !current_user.company.nil?
      company = current_user.company
      # remove parameters with blank values (e.g. prompt options)
      order_filter = filter_order_params.reject{|_, v| v.blank?}
      unless search_order_params.blank?
        results = Order.search_for(search_order_params[:search_query])
        @orders = results.where(order_filter).page params[:page]
      else
       # convert active param to boolean value
        @orders = company.orders(order_filter).page params[:page]
      end
    else
      @orders = []
    end
  end

  def show
    if current_user
      if current_user.is_admin? || (current_user.is_superadmin? && current_user.company_id?) || current_user.is_planer?
        if @order.status == OrderStatusEnum::COMPLETED && !@order.get_assigned_tour
          flash.now[:warning] = t('orders.show.assigned_tour_does_not_exist_html')
        end
        @order
      end
    end
  end

  def new
    if current_user
      if current_user.is_admin? || current_user.is_planer? || (current_user.is_superadmin? && current_user.company_id?)
        @order = Order.new
      end
    end
  end

  def edit
    @order.intToTime
  end

  def create
    @order = Order.new(order_params)
    if @order.save
      flash[:success] = t('.success')
      respond_with(@order)
    else
       flash[:alert] = t('.failure')
       render 'new'
    end
  end

  def update
    @order.process_validity_geocoords()
    if @order.update(order_params)
      flash[:success] = t('.success')
      respond_with(@order)
    else
      flash[:alert] = t('.failure')
      render("edit")
    end
  end

  def destroy
    tour = @order.get_assigned_tour
    if tour
      if !tour.started? && !tour.completed?
        if @order.destroy
          flash[:success] = t('.success')
          respond_with(@order)
        else
          flash[:alert] = t('.failure')
          respond_with(@order)
        end
      else
        flash[:alert] = t('.failure_due_tour_status')
        respond_with(@order)
      end
    else
      if @order.destroy
        flash[:success] = t('.success')
        respond_with(@order)
      else
        flash[:alert] = t('.failure')
        respond_with(@order)
      end
    end
  end

  private
    def set_order
      @order = Order.find(params[:id])
    end

    def order_params
      params.require(:order).permit(:address, :customer_id, :order_ref, :location, :capacity, :start_time, :end_time, :comment, :duration, :status, :order_type, :hour, :minute)
    end

    def filter_order_params
      params.permit(:order_type, :status)
    end

    def search_order_params
      params.permit(:search_query)
    end
end
