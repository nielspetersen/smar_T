class AddIndexDomainInCompanies < ActiveRecord::Migration
  def change
    add_index :companies, :domain, unique: true
  end
end
