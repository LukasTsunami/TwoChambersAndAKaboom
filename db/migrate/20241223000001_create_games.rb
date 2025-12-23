class CreateGames < ActiveRecord::Migration[8.0]
  def change
    create_table :games do |t|
      t.string :code, null: false, index: { unique: true }
      t.string :status, default: 'waiting' # waiting, playing, leader_selection, hostage_exchange, finished
      t.integer :round_time, default: 180 # 3 minutos por padrão
      t.integer :current_round, default: 0
      t.integer :total_rounds, default: 3
      t.string :winning_team # red, blue
      t.datetime :round_started_at
      t.datetime :round_ends_at

      t.timestamps
    end
  end
end

