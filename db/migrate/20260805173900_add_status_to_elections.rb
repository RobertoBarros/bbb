class AddStatusToElections < ActiveRecord::Migration[8.1]
  def change
    add_column :elections, :status, :integer, default: 0, null: false
  end
end
