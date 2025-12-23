class CreatePlayers < ActiveRecord::Migration[8.0]
  def change
    create_table :players do |t|
      t.string :name, null: false
      t.string :session_token, null: false, index: { unique: true }
      t.references :game, null: true, foreign_key: true
      t.string :team # red, blue
      t.string :role # president, bomber, regular
      t.integer :room # 1 ou 2
      t.boolean :is_creator, default: false
      t.boolean :is_leader, default: false
      t.boolean :is_hostage, default: false

      t.timestamps
    end
  end
end

