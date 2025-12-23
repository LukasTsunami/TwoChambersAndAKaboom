class AddLeaderVoteToPlayers < ActiveRecord::Migration[8.0]
  def change
    add_column :players, :leader_vote_id, :integer
    add_index :players, :leader_vote_id
  end
end

