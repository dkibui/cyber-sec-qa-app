class CreateProjects < ActiveRecord::Migration[8.1]
  def change
    create_table :projects do |t|
      t.string :name, null: false
      t.integer :stage, null: false, default: 0   # 0 = design
      t.references :architect, foreign_key: { to_table: :users }
      t.references :developer, foreign_key: { to_table: :users }
      t.timestamps
    end
  end
end
