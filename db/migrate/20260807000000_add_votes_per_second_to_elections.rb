class AddVotesPerSecondToElections < ActiveRecord::Migration[8.1]
  def change
    add_column :elections, :votes_per_second, :decimal, precision: 15, scale: 6, default: 0, null: false
  end
end
