class CreateEvidences < ActiveRecord::Migration[8.1]
  def change
    create_table :evidences do |t|
      t.references :finding, null: false, foreign_key: true
      t.string :caption, null: false
      t.timestamps
    end
  end
end
