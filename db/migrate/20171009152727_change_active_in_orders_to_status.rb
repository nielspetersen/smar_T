class ChangeActiveInOrdersToStatus < ActiveRecord::Migration
  def change
    rename_column :orders, :active, :status
    change_column :orders, :status, :integer, default: 1
  end
end
