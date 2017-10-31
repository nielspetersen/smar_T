class MergeRedundantDurationFieldsToOrders < ActiveRecord::Migration
  def up
    add_column :orders, :duration, :integer, default: 0

    Order.find_each do |order|
      case order.order_type
        when 0
          order.duration = order.duration_delivery
        when 1
          order.duration = order.duration_pickup
        when 2
          order.duration = order.duration_delivery
      end
      order.save!
    end

    remove_column :orders, :duration_delivery, :integer, default: 0
    remove_column :orders, :duration_pickup, :integer, default: 0
  end

  def down
    add_column :orders, :duration_delivery, :integer, default: 0
    add_column :orders, :duration_pickup, :integer, default: 0

    Order.find_each do |order|
      case order.order_type
        when 0
          order.duration_delivery = order.duration
        when 1
          order.duration_pickup = order.duration
        when 2
          order.duration_delivery = order.duration
      end
      order.save!
    end

    remove_column :orders, :duration, :integer, default: 0
  end
end
