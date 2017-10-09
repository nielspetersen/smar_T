class RemoveIndexDriverFromVehicle < ActiveRecord::Migration
  def change
  add_reference :vehicles, :company, index: true
  remove_index :vehicles, name: "index_vehicles_on_driver_id"
  end
end
