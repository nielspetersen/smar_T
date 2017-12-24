FactoryBot.define do
  factory :customer do
    name Faker::Name.name
    address Faker::Address.street_name + " " + Faker::Address.building_number + " " + Faker::Address.postcode + " "  + Faker::Address.city
    priority 'A'
  end
end
