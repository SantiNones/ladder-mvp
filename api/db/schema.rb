# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_07_31_190004) do
  create_table "criteria", force: :cascade do |t|
    t.string "code", null: false
    t.string "competency", null: false
    t.datetime "created_at", null: false
    t.integer "level_position", null: false
    t.string "source", null: false
    t.text "text", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_criteria_on_code", unique: true
  end

  create_table "evidences", force: :cascade do |t|
    t.integer "author_id", null: false
    t.string "author_relation", null: false
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.integer "criterion_id", null: false
    t.date "occurred_on", null: false
    t.integer "person_id", null: false
    t.string "source_type", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_evidences_on_author_id"
    t.index ["criterion_id"], name: "index_evidences_on_criterion_id"
    t.index ["person_id"], name: "index_evidences_on_person_id"
  end

  create_table "people", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "level_position", null: false
    t.integer "manager_id"
    t.string "name", null: false
    t.string "role", null: false
    t.datetime "updated_at", null: false
    t.index ["manager_id"], name: "index_people_on_manager_id"
  end

  create_table "snapshots", force: :cascade do |t|
    t.datetime "closed_at", null: false
    t.datetime "created_at", null: false
    t.string "cycle_label", null: false
    t.json "gap", default: [], null: false
    t.integer "level_position_at_close", null: false
    t.json "met", default: [], null: false
    t.text "narrative"
    t.integer "person_id", null: false
    t.json "prompt_payload"
    t.integer "target_level_position", null: false
    t.datetime "updated_at", null: false
    t.date "window_end", null: false
    t.date "window_start", null: false
    t.index ["person_id", "cycle_label"], name: "index_snapshots_on_person_id_and_cycle_label", unique: true
    t.index ["person_id"], name: "index_snapshots_on_person_id"
  end

  add_foreign_key "evidences", "criteria"
  add_foreign_key "evidences", "people"
  add_foreign_key "evidences", "people", column: "author_id"
  add_foreign_key "people", "people", column: "manager_id"
  add_foreign_key "snapshots", "people"
end
