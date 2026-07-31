class CreateCriteria < ActiveRecord::Migration[8.1]
  def change
    create_table :criteria do |t|
      t.string :code, null: false
      t.integer :level_position, null: false
      t.string :competency, null: false
      t.text :text, null: false
      t.string :source, null: false

      t.timestamps
    end

    add_index :criteria, :code, unique: true
  end
end
