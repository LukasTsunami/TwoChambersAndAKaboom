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

ActiveRecord::Schema[8.1].define(version: 2024_12_23_000007) do
  create_table "card_shares", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "from_player_id", null: false
    t.integer "game_id", null: false
    t.integer "round"
    t.string "share_type", default: "card", null: false
    t.string "status", default: "pending", null: false
    t.integer "to_player_id", null: false
    t.datetime "updated_at", null: false
    t.index ["from_player_id"], name: "index_card_shares_on_from_player_id"
    t.index ["game_id", "from_player_id", "to_player_id", "round"], name: "index_card_shares_on_game_players_round"
    t.index ["game_id"], name: "index_card_shares_on_game_id"
    t.index ["to_player_id"], name: "index_card_shares_on_to_player_id"
  end

  create_table "games", force: :cascade do |t|
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.integer "current_round", default: 0
    t.string "role_selection_mode", default: "manual"
    t.datetime "round_ends_at"
    t.datetime "round_started_at"
    t.integer "round_time", default: 180
    t.text "selected_roles"
    t.string "status", default: "waiting"
    t.integer "total_rounds", default: 3
    t.datetime "updated_at", null: false
    t.string "winning_team"
    t.index ["code"], name: "index_games_on_code", unique: true
  end

  create_table "players", force: :cascade do |t|
    t.boolean "ability_used", default: false
    t.datetime "created_at", null: false
    t.string "gambler_guess"
    t.integer "game_id"
    t.boolean "is_creator", default: false
    t.boolean "is_hostage", default: false
    t.boolean "is_infected", default: false
    t.boolean "is_leader", default: false
    t.integer "leader_vote_id"
    t.string "name", null: false
    t.string "original_role"
    t.string "pin", limit: 3
    t.string "role"
    t.integer "room"
    t.string "session_token", null: false
    t.text "stepfather_children"
    t.string "team"
    t.integer "times_was_leader_room1", default: 0
    t.integer "times_was_leader_room2", default: 0
    t.datetime "updated_at", null: false
    t.index ["game_id"], name: "index_players_on_game_id"
    t.index ["leader_vote_id"], name: "index_players_on_leader_vote_id"
    t.index ["session_token"], name: "index_players_on_session_token", unique: true
  end

  add_foreign_key "card_shares", "games"
  add_foreign_key "card_shares", "players", column: "from_player_id"
  add_foreign_key "card_shares", "players", column: "to_player_id"
  add_foreign_key "players", "games"
end
