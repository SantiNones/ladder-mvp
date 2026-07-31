class CreatePeople < ActiveRecord::Migration[8.1]
  def change
    create_table :people do |t|
      t.string :name, null: false
      t.string :role, null: false
      t.references :manager, foreign_key: { to_table: :people }, null: true
      t.integer :level_position, null: false

      t.timestamps
    end
  end
end
