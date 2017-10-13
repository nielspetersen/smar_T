class CompaniesController < ApplicationController
  before_action :set_company, only: [:show, :edit, :update, :destroy]

  respond_to :html

  def index
    # Nur Daten die Zur Rolle passen anzeigen --> usually here .is_admin?
    if current_user && current_user.is_superadmin?
        # remove the company of the super admin
        current_user.company = nil
        current_user.save
        @companies = Company.all
    end
  end

  def show
    if current_user
      if current_user.is_superadmin? && !current_user.company_id?
        # set the selected company as the company of the super admin
        current_user.company = @company
        current_user.save
        @company
      end
      if (current_user.is_superadmin? && current_user.company_id?)  || current_user.is_admin?
        @company
      end
    end
  end

  def new
    if current_user && current_user.is_superadmin? && !current_user.company_id?
      @company = Company.new
    end
  end

  def edit
    # FIXME
  end

  def create
    @company = Company.new(company_params)
    if @company.save
      restriction = Restriction.new
      restriction.company = @company
      restriction.problem = "DP"
      restriction.save
      User.create!(company: @company, nickname: "Administrator @ " + @company.name, email: @company.email, password: "password", role: "admin")

      flash[:success] = t('.success', company_name: @company.name)
      redirect_to companies_path
    else
      flash[:alert] = t('.failure')
      render 'new'
    end
  end

  def update
    if @company.update(company_params)
      if company_params[:logo].blank?
        @company.logo.destroy
      end
      flash[:success] = t('.success', company_name: @company.name)
      respond_with(@company)
    else
      flash[:alert] = t('.failure', company_name: @company.name)
      render("edit")
    end
  end

  def destroy
    if @company.destroy
      flash[:success] = t('.success', company_name: @company.name)
      respond_with(@company)
    else
      flash[:alert] = t('.failure', company_name: @company.name)
      respond_with(@company)
    end
  end

  private
    def set_company
      @company = Company.find(params[:id])
    end

    def company_params
      params.require(:company).permit(:user_id, :name, :address, :email, :telefon, :google_maps_api_key, :logo)
    end
end
