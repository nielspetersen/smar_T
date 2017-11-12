class AddOrderRefToOrder < ActiveRecord::Migration
  def change
    add_column :orders, :order_ref, :string, null: true
  end
end
