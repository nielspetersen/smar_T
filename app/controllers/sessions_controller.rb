class SessionsController < Devise::SessionsController
  after_filter :set_google_maps_api_key, :only => :create
  before_filter :unassign_superadmin, :only => :create

  def set_google_maps_api_key
    Geocoder.configure(api_key: current_user.try(:company).try(:google_maps_api_key))
  end

  def unassign_superadmin
    user = User.where(role: "superadmin").first
    if !user.nil?
      user.company = nil
      user.save
    end
  end
end