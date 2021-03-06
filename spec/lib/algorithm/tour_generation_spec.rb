require 'rails_helper'
require 'algorithm/tour_generation'

RSpec.describe "TourGeneration" do

  context ".preprocess" do
    let!(:company) { FactoryBot.create(:company)}
    let!(:depot) { FactoryBot.create(:depot, company: company, address: company.address) }
    let!(:user_1) { FactoryBot.create(:user_driver, password: "password", company: company) }
    let!(:user_2) { FactoryBot.create(:user_driver, password: "password", company: company) }
    let!(:customer_1) { FactoryBot.create(:customer, company: company) }
    let!(:customer_2) { FactoryBot.create(:customer, company: company) }
    let!(:order_1) { FactoryBot.create(:delivery_order, customer: customer_1) }
    let!(:order_2) { FactoryBot.create(:delivery_order, customer: customer_2, start_time: nil) }
    let!(:order_3) { FactoryBot.create(:delivery_order, customer: customer_1, start_time: DateTime.now + 24.hours) }
    let!(:order_4) { FactoryBot.create(:delivery_order, customer: customer_1, status: OrderStatusEnum::INACTIVE) }
    let!(:driver_1) { FactoryBot.create(:active_driver, user: user_1) }
    let!(:driver_2) { FactoryBot.create(:inactive_driver, user: user_2) }
    let!(:vehicle_1) { FactoryBot.create(:vehicle, driver: driver_1, position: company.address) }
    let!(:vehicle_2) { FactoryBot.create(:vehicle, driver: driver_2, position: company.address) }
    let(:preprocessed_output) { Algorithm::TourGeneration.preprocess(company.orders, company.available_drivers) }

    it "returns only due / active orders" do
      expect(preprocessed_output[0]).to include(order_1)
      expect(preprocessed_output[0]).to include(order_2)
      expect(preprocessed_output[0]).not_to include(order_3)
      expect(preprocessed_output[0]).not_to include(order_4)
    end

    it "returns only active drivers" do
      expect(preprocessed_output[1]).to include(driver_1)
      expect(preprocessed_output[1]).not_to include(driver_2)
    end
  end
end
