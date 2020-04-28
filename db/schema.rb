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

ActiveRecord::Schema.define(version: 2020_04_24_200137) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "resources", force: :cascade do |t|
    t.string "callback_url", null: false
    t.string "name", null: false
    t.uuid "grant_code", null: false
    t.datetime "grant_expires_at", null: false
    t.string "grant_type", null: false
    t.string "oauth_token"
    t.string "oauth_refresh_token"
    t.string "oauth_token_expires_at"
    t.jsonb "options", default: "'{}'::jsonb"
    t.string "plan", null: false
    t.string "region"
    t.uuid "external_id", null: false
    t.string "log_drain_token", null: false
    t.string "state", default: "pending"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["external_id"], name: "index_resources_on_external_id", unique: true
  end

end
