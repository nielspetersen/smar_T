class AddOrderTypeToOrders < ActiveRecord::Migration
  def change
    add_column :orders, :order_type, :integer, default: 0
  end
end
