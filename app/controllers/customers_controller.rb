class CustomersController < ApplicationController
  before_action :set_customer, only: [:show, :edit, :update, :destroy]

  respond_to :html

  def index
    if current_user.is_planer? || current_user.is_admin? || (current_user.is_superadmin? && current_user.company_id?)
      @customers = Customer.where(company_id: current_user.company_id).page params[:page]
    end
  end

  def show
    if current_user
      if @customer.company_id == current_user.company_id && (current_user.is_planer? || current_user.is_admin? || (current_user.is_superadmin? && current_user.company_id?))
      @customer
      end
    end
  end

  def new
    if current_user
      if current_user.is_admin? || current_user.is_planer? || (current_user.is_superadmin? && current_user.company_id?)
        @customer = Customer.new
        @customer.company_id = current_user.company_id
      end
    end
  end

  def edit
    # FIXME
  end

  def create
    @customer = Customer.new(customer_params)
    @customer.company_id = current_user.company.id
    if @customer.save
      flash[:success] = t('.success')
      redirect_to customers_path
    else
      flash[:alert] = t('.failure')
      render 'new'
    end
  end

  def update
    if @customer.update(customer_params)
    flash[:success] = t('.success')
    respond_with(@customer)
    else
    flash[:alert] = t('.failure')
    render("edit")
   end
  end

  def destroy
    if @customer.destroy
    flash[:success] = t('.success')
    respond_with(@customer)
    else
    flash[:alert] = t('.failure')
    respond_with(@customer)
    end
  end

  private
    def set_customer
      @customer = Customer.find(params[:id])
    end

    def customer_params
      params.require(:customer).permit(:user_id, :name, :company_id, :address, :telefon, :priority)
    end
end
