class OrderImportController < ApplicationController
  include OrderImportHelper

  def file
  end

  def confirm
    import_file = params[:file]
    new_order_ids = []
    if import_file
      CSV.foreach(import_file.path, col_sep: ";", encoding: 'UTF-8') do |row|
        if is_number?(row[0].squish) # ignore header and validate customer_reference
          order = Order.new
          order.customer = Customer.customer_by_customer_reference(row[0].squish.to_i, current_user.company, row[1].squish, row[3].squish)
          order.location = row[2].squish
          order.duration = row[4].squish
          order.capacity = 0
          order.status = OrderStatusEnum::INVALID
          order.comment = ""
          order.comment2 = ""
          order.save!
          new_order_ids.push(order.id)
        end
      end
    end
    @check_orders = Order.where(id: new_order_ids)
    @check_orders.each do |order|
      if order.lat && order.long
      order.status = OrderStatusEnum::ACTIVE
      order.save!
      end
    end
    @imported_orders = Order.where(id: new_order_ids).where.not(status: 4)
    @invalid_orders = Order.where(id: new_order_ids).where(status: 4)
  end

  def complete
    # saves orders after confirmation
    if Order.update(params[:orders].keys, params[:orders].values)
      flash[:success] = t('.success')
    else
      flash[:failure] = t('.failure')
    end
    redirect_to orders_path
  end

  private

    def order_import_params
      params.require(:order_import).permit(:file, :orders)
    end

end
