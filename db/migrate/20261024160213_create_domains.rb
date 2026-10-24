class CreateDomains < ActiveRecord::Migration[8.1]
  def change
    create_table :domains do |t|
      t.integer :number, null: false
      t.string :name, null: false

      t.timestamps
    end
    add_index :domains, :number, unique: true
    add_index :domains, :name, unique: true
  end
end
