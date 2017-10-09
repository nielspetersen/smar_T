class UserForm
  include ActiveModel::Model

  attr_accessor :user_id, :name, :work_start_time, :work_end_time, :active, :working_time, :id, :email, :company_id, :password, :last_sign_in_at, :created_at, :username, :role

  validates :username, :email, presence: true
  validates :password, presence: true, :if => :id?
  validates :role, inclusion: { in: ["superadmin","admin", "planer", "driver", "user", "guest"],
    message: "%{value} is not a valid role." }, presence: true
  validates :working_time, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 1440 }, :if => :driver_selected?

  def driver_selected?
     role ==  'driver'
  end
  
 def initialize(attr = {})
 if !attr["id"].nil?
    @user = User.find(attr["id"])
    self.username = attr[:username].nil? ? @user.username : attr[:username]
    self.email = attr[:email].nil? ? @user.email : attr[:email]
    self.role = attr[:role].nil? ? @user.role : attr[:role]
    self.id = @user.id

    if @user.role == "driver"
    @driver = Driver.find_by_user_id(@user.id)
    self.working_time = attr[:working_time].nil? ? @driver.working_time : attr[:working_time]
    self.active = attr[:active].nil? ? @driver.active : attr[:active]
    elsif (@user.role == "planer" && attr[:role] == "driver") 
    self.working_time = attr[:working_time].nil? ? @driver.working_time : attr[:working_time]
    self.active = attr[:active].nil? ? @driver.active : attr[:active]
    end
   
 else
   super(attr)
 end
end

def persisted?
    @user.nil? ? false : @user.persisted?
end

def id
   @user.nil? ? nil : @user.id
end

def id?
   id.nil?
end

   def save
      if valid?
          persist_user
          if role == "driver"
          persist_driver
          end
          true
       else
           false
      end

     end

def update
    if valid?
        if @user.role == "planer" && role == "driver"
        	persist_driver
        	update_user
        elsif @user.role == "driver" && role == "planer"
                @driver.destroy
                 update_user
        else
		update_user
		if @user.role == "driver"
        	update_driver
		end
        
        end  
         

        true
    else
        false
    end
end

private

      def persist_user
        @user = User.new(email: email, company_id: company_id, password: password, username: username, role:role)
        @user.save
      end

     def persist_driver
          @driver = Driver.new(user_id: @user.id, name: username, active: active, working_time: working_time)
          @driver.save
     end

   def update_user
    
    @user.update_attributes(
        :username => username,
        :email => email,
        :role => role)
   end

  def update_driver
   
    @driver.update_attributes(
        :name => username,
        :active => active,
        :working_time => working_time
        )
   end


end

