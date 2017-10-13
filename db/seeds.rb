# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

User.create!(nickname: "Superadmin @ smar_T", email: "superadmin@smart.de", password: "password", role: "superadmin")
# User.create!(username: "admin", email: "test@test.de", password: "password", role: "admin")
# User.create!(username: "planer", email: "planer@test.de", password: "password", role: "planer")
# User.create!(username: "driver", email: "driver@test.de", password: "password", role: "driver")
# User.create!(username: "user", email: "user@test.de", password: "password", role: "user")

# Create sample company
# Company.create(name: "My company", address: "Alexanderplatz 7, 10178 Berlin")

# Create sample customers for all categorical priorities
# Customer.create(name: "Customer Prio A", company_id: Company.first.id, priority: "A")
# Customer.create(name: "Customer Prio B", company_id: Company.first.id, priority: "B")
# Customer.create(name: "Customer Prio C", company_id: Company.first.id, priority: "C")
# Customer.create(name: "Customer Prio D", company_id: Company.first.id, priority: "D")
# Customer.create(name: "Customer Prio E", company_id: Company.first.id, priority: "E")
