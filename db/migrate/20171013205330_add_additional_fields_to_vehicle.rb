class AddAdditionalFieldsToVehicle < ActiveRecord::Migration
  def change
    add_column :vehicles, :model, :string
    add_column :vehicles, :registration_number, :string, unique: true
    add_column :vehicles, :manufacturer, :string
  end
end
