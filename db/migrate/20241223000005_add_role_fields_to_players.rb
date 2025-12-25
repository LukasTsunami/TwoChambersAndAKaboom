class AddRoleFieldsToPlayers < ActiveRecord::Migration[8.0]
  def change
    add_column :players, :ability_used, :boolean, default: false
    add_column :players, :is_infected, :boolean, default: false
    add_column :players, :stepfather_children, :text # JSON array of player IDs
    add_column :players, :gambler_guess, :string # 'blue', 'red', 'green', or 'black'
    add_column :players, :times_was_leader_room1, :integer, default: 0
    add_column :players, :times_was_leader_room2, :integer, default: 0
    add_column :players, :original_role, :string # Para rastrear role original após troca (Batata Quente)
  end
end

