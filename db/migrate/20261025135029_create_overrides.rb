class CreateOverrides < ActiveRecord::Migration[8.1]
  def change
    create_table :overrides do |t|
      t.references :assessment, null: false, foreign_key: true, index: { unique: true }
      t.references :approver, null: false, foreign_key: { to_table: :users }
      t.text :comments, null: false
      t.timestamps
    end
  end
end
