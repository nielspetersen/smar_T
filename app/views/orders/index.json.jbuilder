json.array!(@orders) do |order|
  json.extract! order, :id, :customer_id, :location, :capacity, :start_time, :end_time
  json.url order_url(order, format: :json)
end
