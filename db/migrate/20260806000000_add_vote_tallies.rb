class AddVoteTallies < ActiveRecord::Migration[8.1]
  def change
    add_column :candidacies, :votes_count, :integer, default: 0, null: false
    add_column :elections, :tallied_at, :datetime
  end
end
