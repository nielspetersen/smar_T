class OrdersController < ApplicationController
  include OrdersHelper
  before_action :set_order, only: [:show, :edit, :update, :destroy]

  respond_to :html

  def index
    if (current_user.is_admin? || current_user.is_planer? || (current_user.is_superadmin? && current_user.company_id?)) && !current_user.company.nil?
      company = current_user.company
      # remove parameters with blank values (e.g. prompt options)
      order_filter = filter_order_params.reject{|_, v| v.blank?}
      # convert active param to boolean value
      if order_filter[:active]
        order_filter[:active] = to_boolean(order_filter[:active])
      end
      @orders = company.orders(order_filter)
    else
      @orders = []
    end
  end

  def show
    if current_user
      if current_user.is_admin? || (current_user.is_superadmin? && current_user.company_id?)
        @order
      elsif current_user.is_planer?
### working
        if @order.company.id == current_user.company_id
          @order
        end
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
  end

  def create
    @order = Order.new(order_params)
    if @order.save
      flash[:success] = t('.success', order_id: @order.id)
    respond_with(@order)
      else
       flash[:alert] = t('.failure')
       render 'new'
    end
  end

  def update
    if @order.update(order_params)
      flash[:success] = t('.success', order_id: @order.id)
    respond_with(@order)
      else
      flash[:alert] = t('.failure', order_id: @order.id)
      render("edit")
    end
  end

  def destroy
    if @order.destroy
      flash[:success] = t('.success', order_id: @order.id)
    respond_with(@order)
      else
      flash[:alert] = t('.failure', order_id: @order.id)
      respond_with(@order)
    end
  end

  def import
    # todo: import orders from uploaded file
  end

  private
    def set_order
      @order = Order.find(params[:id])
    end

    def order_params
      params.require(:order).permit(:address, :customer_id, :pickup_location, :delivery_location, :capacity, :start_time, :end_time, :comment, :duration_pickup, :duration_delivery, :active, :order_type)
    end

    def filter_order_params
      params.permit(:order_type, :active)
    end
end
