module OrdersHelper
  def to_boolean(value)
    value.downcase == "1"
  end
end
