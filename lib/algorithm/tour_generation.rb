require 'algorithm/variants/savingsplusplus'
require 'algorithm/variants/mthreetp'

module Algorithm

  class TourGeneration

    def self.generate_tours(company, order_type_filter = {})
      # clear all tours with status equal to generated
      Tour.where(status: StatusEnum::GENERATED).destroy_all

      orders, drivers  = preprocess(company.orders(order_type_filter), company.available_drivers)
      # only start tour generation when orders and available driver exist
      if orders.any? && drivers.any?
        mthreetp_classic = Variants::MThreeTP.new(company, AlgorithmEnum::M3PDP)
        mthreetp_classic.run(orders, drivers)

        mthreetp_delta = Variants::MThreeTP.new(company, AlgorithmEnum::M3PDPDELTA)
        mthreetp_delta.run(orders, drivers)

        savingsplusplus = Variants::SavingsPlusPlus.new(company)
        savingsplusplus.run(orders, drivers)

        compare_and_destroy_tours()
      end
    end


    def self.preprocess(all_orders, drivers)
      orders = preprocess_orders(all_orders)
      return orders, drivers
    end

    def self.preprocess_orders(all_orders)
      active_orders = all_orders.where(status: OrderStatusEnum::ACTIVE)
      orders = []
      active_orders.each do |order|
        if !order.start_time || order.start_time.try(:today?)
          orders.push(order)
        end
      end
      orders.sort_by! { |order| [order.start_time ? 0 : 1, order.start_time] }
      orders
    end

    def self.compare_and_destroy_tours()
      tours_duration = Array.new([AlgorithmEnum::M3PDP, AlgorithmEnum::M3PDPDELTA, AlgorithmEnum::SAVINGSPP].length)

      m3pdp_tours = Tour.where(status: StatusEnum::GENERATED, algorithm: AlgorithmEnum::M3PDP)
      m3pdp_delta_tours = Tour.where(status: StatusEnum::GENERATED, algorithm: AlgorithmEnum::M3PDPDELTA)
      saving_tours = Tour.where(status: StatusEnum::GENERATED, algorithm: AlgorithmEnum::SAVINGSPP)

      tours_duration[AlgorithmEnum::M3PDP] = m3pdp_tours.inject(0){ |sum, x| sum + x.duration }
      tours_duration[AlgorithmEnum::M3PDPDELTA] = m3pdp_delta_tours.inject(0){ |sum, x| sum + x.duration}
      tours_duration[AlgorithmEnum::SAVINGSPP] = saving_tours.inject(0){ |sum, x| sum + x.duration }

      best_algorithm_index = tours_duration.each_with_index.min[1] # index of the min value in array

      # change status of selected tour combination to approved and from orders to assigned
      Tour.where(status: StatusEnum::GENERATED).where(algorithm: best_algorithm_index).each do |tour|
        tour.update_attributes(status: StatusEnum::APPROVED)
        tour.order_tours.each do |order_tour|
          if ['delivery', 'pickup', 'service'].include? order_tour.kind
            order_tour.order.update_attributes(status: OrderStatusEnum::ASSIGNED)
          end
        end
      end
      # delete inefficient tour combinations
      Tour.where(status: StatusEnum::GENERATED).where.not(algorithm: best_algorithm_index).destroy_all
    end
  end
end
