class CreateFindings < ActiveRecord::Migration[8.1]
  def change
    create_table :findings do |t|
      t.references :assessment, null: false, foreign_key: true
      t.references :control_result, null: false, foreign_key: true
      t.string :category
      t.text :test_objective
      t.text :observations
      t.timestamps
    end
  end
end
