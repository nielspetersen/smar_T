class MergeRedundantFieldsForLocationToOrders < ActiveRecord::Migration
  def up
    add_column :orders, :location, :string
    add_column :orders, :lat, :float
    add_column :orders, :long, :float

    # transfer data to new columns
    Order.find_each do |order|
      case order.order_type
        when 0
          order.location = order.delivery_location
          order.lat = order.delivery_lat
          order.long = order.delivery_long
        when 1
          order.location = order.pickup_location
          order.lat = order.pickup_lat
          order.long = order.pickup_long
        else
          order.location = order.delivery_location
          order.lat = order.delivery_lat
          order.long = order.delivery_long
      end
      order.save!
    end

    remove_column :orders, :delivery_location, :string
    remove_column :orders, :delivery_lat, :float
    remove_column :orders, :delivery_long, :float
    remove_column :orders, :pickup_location, :string
    remove_column :orders, :pickup_lat, :float
    remove_column :orders, :pickup_long, :float
  end

  def down
    add_column :orders, :delivery_location, :string
    add_column :orders, :delivery_lat, :float
    add_column :orders, :delivery_long, :float
    add_column :orders, :pickup_location, :string
    add_column :orders, :pickup_lat, :float
    add_column :orders, :pickup_long, :float


    # transfer data to new columns
    Order.find_each do |order|
      case order.order_type
        when 0
          order.delivery_location =  order.location
          order.delivery_lat = order.lat
          order.delivery_long = order.long
        when 1
          order.pickup_location = order.location
          order.pickup_lat = order.lat
          order.pickup_long = order.long
        else
          order.delivery_location =  order.location
          order.delivery_lat = order.lat
          order.delivery_long = order.long
      end
      order.save!
    end

    remove_column :orders, :location, :string
    remove_column :orders, :lat, :float
    remove_column :orders, :long, :float
  end
end
