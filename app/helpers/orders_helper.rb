module OrdersHelper
  def to_boolean(value)
    value.downcase == "1"
  end

  def order_type_as_string(type)
    case type
      when 0
        t('orders.types.delivery')
      when 1
        t('orders.types.pickup')
      when 2
        t('orders.types.service')
      else
        ""
    end
  end

  def order_status_as_string(status)
    case status
      when 0
        t('orders.status.inactive')
      when 1
        t('orders.status.active')
      when 2
        t('orders.status.assigned')
      when 3
        t('orders.status.completed')
      else
        ""
    end
  end
end
