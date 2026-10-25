class CreateAssessments < ActiveRecord::Migration[8.1]
  def change
    create_table :assessments do |t|
      t.references :project, null: false, foreign_key: true
      t.integer :gate, null: false                       # 0 = design, 1 = testing
      t.integer :round, null: false, default: 1
      t.references :tester, foreign_key: { to_table: :users }
      t.text :components_in_scope
      t.integer :outcome, null: false, default: 0        # 0 = in progress
      t.datetime :decided_at
      t.timestamps
    end
    add_index :assessments, [ :project_id, :gate, :round ], unique: true
  end
end