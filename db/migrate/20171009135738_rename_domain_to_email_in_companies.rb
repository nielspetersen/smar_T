class RenameDomainToEmailInCompanies < ActiveRecord::Migration
  def change
    rename_column :companies, :domain, :email
  end
end
