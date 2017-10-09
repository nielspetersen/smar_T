class UserFormsController < ApplicationController
  respond_to :html

  def new
    @user_form = UserForm.new
    @user_form.active = true
  end

  def edit
   @user_form = UserForm.new("id" => params[:id])
  end


  def create
    @user_form = UserForm.new(user_form_params)
    @user_form.company_id = current_user.company_id
    if @user_form.save
    flash[:success] = t('.success', user_id: @user_form.id)
    #respond_with @registration, location: some_success_path
   redirect_to registered_users_path
   else
    flash[:alert] = t('.failure')
    render :new
   end
 end
   
  def update
   @user_form = UserForm.new(user_form_params.merge("id" => params[:id]))
   if @user_form.update
     flash[:success] = t('.success', user_id: @user_form.id)
     redirect_to registered_users_path
   else
     flash[:alert] = t('.failure', user_id: @user_form.id)
     render :edit
   end
 end

  private

  def user_form_params
    params.require(:user_form).permit(:user_id, :name, :work_start_time, :work_end_time, :active, :working_time, :id, :email, :company_id, :password, :last_sign_in_at, :created_at, :username, :role)
  end
end
