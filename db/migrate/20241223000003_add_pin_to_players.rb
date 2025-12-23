class AddPinToPlayers < ActiveRecord::Migration[8.0]
  def change
    add_column :players, :pin, :string, limit: 3
    add_index :players, [:name, :pin], unique: true
  end
end

