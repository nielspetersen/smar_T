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
        t('tours.status.generated')
      when StatusEnum::APPROVED
        t('tours.status.approved')
      when StatusEnum::STARTED
        t('tours.status.started')
      when StatusEnum::COMPLETED
        t('tours.status.completed')
    end
  end
end
