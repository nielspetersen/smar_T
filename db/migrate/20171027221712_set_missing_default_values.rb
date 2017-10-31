class SetMissingDefaultValues < ActiveRecord::Migration
  def change
  change_column_default(:customers, :priority, 'A')
  change_column_default(:drivers, :working_time, 0)
  change_column_default(:vehicles, :capacity, 0)
  change_column_default(:orders, :start_time, '2012-01-01 00:00:00')
  change_column_default(:orders, :end_time, '2099-01-01 00:00:00')
  end
end
