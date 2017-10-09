class Customer < ActiveRecord::Base
  belongs_to :company
  has_many :orders, dependent: :destroy
  validates :company, presence: {message: "Dieses Feld muss ausgefüllt werden"}
  validates :name, presence: {message: "Dieses Feld muss ausgefüllt werden"}
  validates :priority, inclusion: { in: ["A", "B", "C", "D", "E"],
  message: "Bitte benutzen Sie A,B,C, D oder E" }

  # Koordinaten aus Adresse
  geocoded_by :address
  after_validation :geocode

  def self.customer_by_customer_reference(reference, company, name, priority)
    customer = Customer.where(customer_reference: reference).first
    if customer.blank?
      Customer.create(customer_reference: reference, company: company, name: name, priority: priority)
      customer = Customer.where(customer_reference: reference).first
    end
    customer
  end
end
