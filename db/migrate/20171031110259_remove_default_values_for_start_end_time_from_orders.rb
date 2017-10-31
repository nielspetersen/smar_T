class RemoveDefaultValuesForStartEndTimeFromOrders < ActiveRecord::Migration
  def change
    change_column_default(:orders, :start_time, nil)
    change_column_default(:orders, :end_time, nil)
  end
end
