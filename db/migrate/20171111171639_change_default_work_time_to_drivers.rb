class ChangeDefaultWorkTimeToDrivers < ActiveRecord::Migration
  def change
    change_column_default :drivers, :working_time, 480
  end
end
