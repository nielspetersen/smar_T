module ToursHelper

  def get_algorithm_display_text(algorithm)
    if algorithm == AlgorithmEnum::M3PDP
      display_text = "M3PDP"
    elsif algorithm == AlgorithmEnum::M3PDPDELTA
      display_text = "M3PDP Delta"
    elsif algorithm == AlgorithmEnum::SAVINGSPP
      display_text = "Savings++"
    end

    display_text
  end

  def is_sortable_order_tour?(order_tour)
    sortable_class = order_tour.kind != "delivery" ? false : true
    sortable_class
  end

  def get_tour_status_as_string(status)
    case status
      when StatusEnum::GENERATED
        t('helpers.tours.tour_generated')
      when StatusEnum::APPROVED
        t('helpers.tours.tour_approved')
      when StatusEnum::STARTED
        t('helpers.tours.tour_started')
      when StatusEnum::COMPLETED
        t('helpers.tours.tour_completed')
    end
  end
end
