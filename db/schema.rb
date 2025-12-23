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

ActiveRecord::Schema[8.1].define(version: 2024_12_23_000002) do
  create_table "games", force: :cascade do |t|
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.integer "current_round", default: 0
    t.datetime "round_ends_at"
    t.datetime "round_started_at"
    t.integer "round_time", default: 180
    t.string "status", default: "waiting"
    t.integer "total_rounds", default: 3
    t.datetime "updated_at", null: false
    t.string "winning_team"
    t.index ["code"], name: "index_games_on_code", unique: true
  end

  create_table "players", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "game_id"
    t.boolean "is_creator", default: false
    t.boolean "is_hostage", default: false
    t.boolean "is_leader", default: false
    t.string "name", null: false
    t.string "role"
    t.integer "room"
    t.string "session_token", null: false
    t.string "team"
    t.datetime "updated_at", null: false
    t.index ["game_id"], name: "index_players_on_game_id"
    t.index ["session_token"], name: "index_players_on_session_token", unique: true
  end

  add_foreign_key "players", "games"
end
