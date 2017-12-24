FactoryBot.define do
  factory :user_driver, class: User do
    username  { Faker::Name.name }
    email { Faker::Internet.email }
    role 'driver'
  end
end
