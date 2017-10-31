class AddDefaultTourStartToCompany < ActiveRecord::Migration
  def change
    add_column :companies, :default_tour_start, :string, default: '9:00'
  end
end
