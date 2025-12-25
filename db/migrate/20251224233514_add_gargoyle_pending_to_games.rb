class AddGargoylePendingToGames < ActiveRecord::Migration[8.1]
  def change
    add_column :games, :gargoyle_pending_decisions, :text
  end
end