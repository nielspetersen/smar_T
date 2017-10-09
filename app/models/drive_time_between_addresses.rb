# takes care of calculating the driving time between two addresess
# the adresses just have to be provided as strings.
# call like so:
# timer = DriveTimeBetweenAddresses.new("Peter-Lurenz-Weg 23 Hamburg", "Kreuzbergring 4 Göttingen")
# timer.drive_time_in_seconds
# #=> 2500
class DriveTimeBetweenAddresses
  attr_reader :origin_address, :target_address
  def initialize(origin_address, target_address, google_maps_api_key)
      @origin_address = origin_address
      @target_address = target_address
      @google_maps_api_key = google_maps_api_key
  end
  
  # returns the time in seconds between the addresses
  def drive_time_in_seconds
      cached_api_call.drive_time_in_minutes*60
  end
  
  # returns the drive time in minutes between the addresses
  def drive_time_in_minutes
      cached_api_call.drive_time_in_minutes
  end
  
  # returns a cached version of the drive time in minutes
  def cached_drive_time_in_minutes
    Rails.cache.fetch(cache_key_minutes, expires_in: 2.hours) do
      drive_time_in_minutes
    end
  end
  
  # returns the drive time in hours between the addresses
  def drive_time_in_hours
      cached_api_call.drive_time_in_minutes / 60
  end
  
  # returns true if we are over the quota limit for the current day.
  def over_query_limit?
      cached_api_call.status == "OVER_QUERY_LIMIT"
  end
  
  
  private
  
  # returns the api call just cached
  def cached_api_call
      # TODO store this in Rails.cache or something.
      @cached_api_call ||= api_call
  end
  
  # returns the raw api data for the call
  def api_call
    GoogleDirections.new(origin_address,
                         target_address,
                         key: @google_maps_api_key)
  end
  
  def cache_key_minutes
    "#{origin_address}-#{target_address}".gsub(" ", "").downcase
  end
  

end