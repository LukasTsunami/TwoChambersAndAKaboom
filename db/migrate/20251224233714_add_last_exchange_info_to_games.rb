class AddLastExchangeInfoToGames < ActiveRecord::Migration[8.1]
  def change
      add_column :games, :last_exchange_info, :text
      add_column :games, :room_change_ends_at, :datetime
  end
end