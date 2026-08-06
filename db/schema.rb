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

ActiveRecord::Schema[8.1].define(version: 2026_08_06_000000) do
  create_table "candidacies", force: :cascade do |t|
    t.integer "candidate_id", null: false
    t.datetime "created_at", null: false
    t.integer "election_id", null: false
    t.datetime "updated_at", null: false
    t.integer "votes_count", default: 0, null: false
    t.index ["candidate_id"], name: "index_candidacies_on_candidate_id"
    t.index ["election_id", "candidate_id"], name: "index_candidacies_on_election_id_and_candidate_id", unique: true
    t.index ["election_id"], name: "index_candidacies_on_election_id"
  end

  create_table "candidates", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
  end

  create_table "elections", force: :cascade do |t|
    t.datetime "closed_at"
    t.datetime "created_at", null: false
    t.datetime "opened_at"
    t.integer "status", default: 0, null: false
    t.datetime "tallied_at"
    t.string "title", null: false
    t.datetime "updated_at", null: false
  end

  create_table "votes", force: :cascade do |t|
    t.integer "candidacy_id", null: false
    t.datetime "created_at", null: false
    t.string "submission_id", null: false
    t.datetime "submitted_at", null: false
    t.datetime "updated_at", null: false
    t.index ["candidacy_id"], name: "index_votes_on_candidacy_id"
    t.index ["submission_id"], name: "index_votes_on_submission_id", unique: true
  end

  add_foreign_key "candidacies", "candidates"
  add_foreign_key "candidacies", "elections"
  add_foreign_key "votes", "candidacies"
end
