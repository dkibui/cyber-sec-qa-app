class CreateControls < ActiveRecord::Migration[8.1]
  def change
    create_table :controls do |t|
      t.references :domain, null: false, foreign_key: true
      t.integer :sequence, null: false
      t.text :description, null: false
      t.string :owasp
      t.string :cwe_nist
      t.integer :default_severity, null: false, default: 1   # 1 = high
      t.datetime :retired_at

      t.timestamps
    end
    add_index :controls, [ :domain_id, :sequence ], unique: true
  end
end
