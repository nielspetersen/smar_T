# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20171009152727) do

  create_table "companies", force: true do |t|
    t.string   "name"
    t.string   "address"
    t.string   "telefon"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.float    "latitude"
    t.float    "longitude"
    t.string   "google_maps_api_key"
    t.string   "logo_file_name"
    t.string   "logo_content_type"
    t.integer  "logo_file_size"
    t.datetime "logo_updated_at"
    t.string   "email"
  end

  add_index "companies", ["email"], name: "index_companies_on_email", unique: true

  create_table "customers", force: true do |t|
    t.integer  "company_id"
    t.string   "address"
    t.string   "telefon"
    t.string   "priority"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
    t.float    "latitude"
    t.float    "longitude"
    t.integer  "customer_reference"
  end

  add_index "customers", ["company_id"], name: "index_customers_on_company_id"

  create_table "depots", force: true do |t|
    t.integer  "company_id"
    t.string   "address"
    t.integer  "duration",   default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
    t.float    "latitude"
    t.float    "longitude"
  end

  add_index "depots", ["company_id"], name: "index_depots_on_company_id"

  create_table "drivers", force: true do |t|
    t.integer  "user_id"
    t.datetime "work_start_time"
    t.datetime "work_end_time"
    t.boolean  "active"
    t.integer  "working_time"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
  end

  add_index "drivers", ["user_id"], name: "index_drivers_on_user_id"

  create_table "order_tours", force: true do |t|
    t.integer  "order_id"
    t.integer  "tour_id"
    t.integer  "place"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "comment"
    t.integer  "capacity_status", default: 0
    t.integer  "time",            default: 0
    t.string   "kind"
  end

  add_index "order_tours", ["order_id"], name: "index_order_tours_on_order_id"
  add_index "order_tours", ["tour_id"], name: "index_order_tours_on_tour_id"

  create_table "orders", force: true do |t|
    t.integer  "customer_id"
    t.string   "pickup_location"
    t.string   "delivery_location"
    t.integer  "capacity",          default: 0
    t.datetime "start_time"
    t.datetime "end_time"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "comment"
    t.integer  "duration_pickup",   default: 0
    t.integer  "duration_delivery", default: 0
    t.integer  "status",            default: 1
    t.float    "pickup_lat"
    t.float    "pickup_long"
    t.float    "delivery_lat"
    t.float    "delivery_long"
    t.string   "comment2"
    t.integer  "order_type",        default: 0
  end

  add_index "orders", ["customer_id"], name: "index_orders_on_customer_id"

  create_table "restrictions", force: true do |t|
    t.integer  "company_id"
    t.string   "problem"
    t.boolean  "dynamic"
    t.boolean  "multi_vehicle"
    t.boolean  "time_window"
    t.boolean  "capacity_restriction"
    t.boolean  "priorities"
    t.boolean  "work_time"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "restrictions", ["company_id"], name: "index_restrictions_on_company_id"

  create_table "tours", force: true do |t|
    t.integer  "driver_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "status"
    t.integer  "algorithm"
  end

  add_index "tours", ["driver_id"], name: "index_tours_on_driver_id"

  create_table "users", force: true do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.string   "username"
    t.string   "role"
    t.integer  "company_id"
    t.string   "nickname"
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  add_index "users", ["username"], name: "index_users_on_username", unique: true

  create_table "vehicles", force: true do |t|
    t.string   "position"
    t.integer  "capacity"
    t.integer  "duration"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.float    "latitude"
    t.float    "longitude"
    t.integer  "company_id"
    t.integer  "driver_id"
  end

  add_index "vehicles", ["company_id"], name: "index_vehicles_on_company_id"
  add_index "vehicles", ["driver_id"], name: "index_vehicles_on_driver_id", unique: true

end
