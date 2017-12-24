FactoryBot.define do
  factory :regular_restriction, class: Restriction do
    multi_vehicle true
    time_window true
    capacity_restriction true
    work_time true
  end

  factory :regular_dp_restriction, parent: :regular_restriction do
    problem "DP"
  end
end
