class VehicleDriverOneToOneRelation < ActiveRecord::Migration
  def change
    remove_column :vehicles, :driver_id
    add_reference :vehicles, :driver, foreign_key: true, index: { unique: true }
  end
end
