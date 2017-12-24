FactoryBot.define do
  factory :delivery_order, class: Order do
    location { Faker::Address.street_name + " " + Faker::Address.building_number + " " + Faker::Address.postcode + " "  + Faker::Address.city }
    capacity 10
    start_time { DateTime.now + 10.minutes }
    end_time { DateTime.now + 2.hours }
    duration 20
    order_type { 'delivery' }
  end

  factory :pickup_order, class: Order do
    location { Faker::Address.street_name + " " + Faker::Address.building_number + " " + Faker::Address.postcode + " "  + Faker::Address.city }
    capacity 10
    start_time { DateTime.now + 10.minutes }
    end_time { DateTime.now + 2.hours }
    duration 20
    order_type { 'pickup' }
  end
end
