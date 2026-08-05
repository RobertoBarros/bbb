class CreateVotingModels < ActiveRecord::Migration[8.1]
  def change
    create_table :elections do |t|
      t.string :title, null: false

      t.timestamps
    end

    create_table :candidates do |t|
      t.string :name, null: false

      t.timestamps
    end

    create_table :candidacies do |t|
      t.references :election, null: false, foreign_key: true
      t.references :candidate, null: false, foreign_key: true

      t.timestamps
    end
    add_index :candidacies, %i[election_id candidate_id], unique: true

    create_table :votes do |t|
      t.references :candidacy, null: false, foreign_key: true

      t.timestamps
    end
  end
end
