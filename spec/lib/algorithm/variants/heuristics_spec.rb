require 'rails_helper'
require 'algorithm/variants/heuristic'

RSpec.describe "Heuristic Base class" do
  let!(:company) { FactoryGirl.create(:company) }
  let!(:depot) { FactoryGirl.create(:depot, company: company, address: company.address) }
  let!(:restriction) { FactoryGirl.create(:regular_dp_restriction, company: company) }
  let!(:user) { FactoryGirl.create(:user_driver, password: "password", company: company) }
  let!(:driver) { FactoryGirl.create(:active_driver, user: user) }
  let!(:vehicle) { FactoryGirl.create(:vehicle, driver: driver, position: company.address) }
  let!(:tour) { Tour.create(driver: driver) }
  let!(:customer) { FactoryGirl.create(:customer, company: company) }
  let!(:vehicle_pos) { OrderTour.create(tour: tour, place: 0, kind: "vehicle_position") }
  let!(:depot) { OrderTour.create(tour: tour, place: 1, kind: "depot") }
  let!(:pickup_order) { FactoryGirl.create(:pickup_order, customer: customer) }
  let!(:pickup_order_tour) { OrderTour.create(tour: tour, order: pickup_order, place: 2, kind: "pickup") }
  let!(:delivery_order) { FactoryGirl.create(:delivery_order, customer: customer) }
  let!(:delivery_order_tour) { OrderTour.create(tour: tour, order: delivery_order, place: 3, kind: "delivery") }
  let!(:home) { OrderTour.create(tour: tour, place: 4, kind: "home") }
  let!(:heuristic) { Algorithm::Variants::Heuristic.new(company) }

  before { allow(heuristic).to receive(:time_for_distance).and_return(10) }

  context "#check_restriction" do
    context "with tour matching all restrictions" do
      before { heuristic.update_capacity(tour) }

      it "returns true" do
        expect(heuristic.check_restriction(tour, driver)).to be(true)
      end
    end

    context "with tour violating capacity restriction" do
      before do
        delivery_order.capacity = 101
        delivery_order.save
        heuristic.update_capacity(tour)
      end

      it "returns false" do
        expect(heuristic.check_restriction(tour, driver)).to eq(false)
      end
    end

    context "with tour violating time window" do
      before do
        delivery_order.end_time = DateTime.now - 5.minutes
        delivery_order.save
      end

      it "returns false" do
        expect(heuristic.check_restriction(tour, driver)).to eq(false)
      end
    end

    context "with tour violating working time" do
      before do
        delivery_order.update_attribute(:duration, 480)
        heuristic.update_order_tour_times(tour.order_tours)
      end

      it "returns false" do
        expect(heuristic.check_restriction(tour, driver)).to eq(false)
      end
    end
  end

  context "#calc_tour_duration" do
    before { heuristic.update_order_tour_times(tour.order_tours) }

    it "returns the duration of the complete tour" do
      expect(tour.duration).to eq(80)
    end

    context "with increased duration of order by 10" do
      before { delivery_order.update(duration: 30) }

      it "returns a by 10 higher duration of the complete tour" do
        expect(tour.duration).to eq(90)
      end
    end

    context "with decreased duration of order by 10" do
      before { delivery_order.update(duration: 10) }

      it "returns a by 10 lower duration of the complete tour" do
        expect(tour.duration).to eq(70)
      end
    end
  end

  context "#update_capacity" do
    before { heuristic.update_capacity(tour) }

    it "increases capacity_status in case of pickup order" do
      pickup_order_tour.reload #loads latest attribute values from database
      expect(pickup_order_tour.reload.capacity_status).to eq(10)
    end

    it "decreases capacity_status in case of delivery order" do
      delivery_order_tour.reload #loads latest attribute values from database
      expect(delivery_order_tour.reload.capacity_status).to eq(0)
    end
  end
end
