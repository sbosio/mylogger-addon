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

ActiveRecord::Schema.define(version: 2020_05_14_140749) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "log_frames", force: :cascade do |t|
    t.bigint "resource_id", null: false
    t.integer "message_count", null: false
    t.string "external_id", null: false
    t.text "frame_content_ciphertext"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["external_id"], name: "index_log_frames_on_external_id", unique: true
    t.index ["resource_id"], name: "index_log_frames_on_resource_id"
  end

  create_table "resources", force: :cascade do |t|
    t.string "callback_url", null: false
    t.string "name", null: false
    t.text "grant_code_ciphertext", null: false
    t.datetime "grant_expires_at", null: false
    t.string "grant_type", null: false
    t.text "access_token_ciphertext"
    t.string "access_token_expires_at"
    t.string "access_token_type"
    t.text "refresh_token_ciphertext"
    t.jsonb "options", default: "'{}'::jsonb"
    t.string "plan", null: false
    t.string "region"
    t.uuid "external_id", null: false
    t.text "log_drain_token", null: false
    t.string "state", default: "pending"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["external_id"], name: "index_resources_on_external_id", unique: true
  end

  add_foreign_key "log_frames", "resources"
end
