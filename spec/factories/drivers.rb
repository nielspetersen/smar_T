FactoryBot.define do
  factory :active_driver, class: Driver do
    name Faker::Name.name
    working_time 480
    active true
  end

  factory :inactive_driver, parent: :active_driver do
    active false
  end
end
