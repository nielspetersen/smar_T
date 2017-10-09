module OrderImportHelper

  def is_number? string
    true if Float(string) rescue false
  end

  def order_type_as_string(type)
    case type
      when 0
        t('orders.types.delivery')
      when 1
        t('orders.types.pickup')
      when 2
        t('orders.types.service')
    end
  end
end
