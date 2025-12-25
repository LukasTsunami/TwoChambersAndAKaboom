class AddRoleConfigToGames < ActiveRecord::Migration[8.0]
  def change
    add_column :games, :selected_roles, :text # JSON array of role keys
    add_column :games, :role_selection_mode, :string, default: 'manual'
  end
end

