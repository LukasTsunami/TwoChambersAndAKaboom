class AddUsurpMessageToGames < ActiveRecord::Migration[8.1]
  def change
    add_column :games, :usurp_message, :string
  end
end
