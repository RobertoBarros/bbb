class AddAsyncVotingMetadata < ActiveRecord::Migration[8.1]
  def change
    add_column :elections, :opened_at, :datetime
    add_column :elections, :closed_at, :datetime
    add_column :votes, :submission_id, :string, null: false
    add_column :votes, :submitted_at, :datetime, null: false
    add_index :votes, :submission_id, unique: true
  end
end
