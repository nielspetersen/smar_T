FactoryBot.define do
  factory :company do
    name Faker::Company.name
    address  { Faker::Address.street_name + " " + Faker::Address.building_number + " " + Faker::Address.postcode + " "  + Faker::Address.city }
    email Faker::Internet.email
  end
end
