class CreateControlResults < ActiveRecord::Migration[8.1]
  def change
    create_table :control_results do |t|
      t.references :assessment, null: false, foreign_key: true
      t.references :control, null: false, foreign_key: true
      t.integer :status, null: false, default: 0         # 0 = pending
      t.integer :severity, null: false, default: 1       # 1 = high
      t.text :comments
      t.string :owner
      t.timestamps
    end
    add_index :control_results, [ :assessment_id, :control_id ], unique: true
  end
end
