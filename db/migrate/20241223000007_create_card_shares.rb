class CreateCardShares < ActiveRecord::Migration[8.0]
  def change
    create_table :card_shares do |t|
      t.references :game, null: false, foreign_key: true
      t.references :from_player, null: false, foreign_key: { to_table: :players }
      t.references :to_player, null: false, foreign_key: { to_table: :players }
      t.string :share_type, null: false, default: 'card' # 'card' ou 'color'
      t.string :status, null: false, default: 'pending' # 'pending', 'accepted', 'rejected'
      t.integer :round # Rodada em que ocorreu

      t.timestamps
    end

    add_index :card_shares, [:game_id, :from_player_id, :to_player_id, :round], 
              name: 'index_card_shares_on_game_players_round'
  end
end

