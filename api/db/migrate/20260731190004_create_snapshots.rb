class CreateSnapshots < ActiveRecord::Migration[8.1]
  def change
    create_table :snapshots do |t|
      t.references :person, null: false, foreign_key: { to_table: :people }
      t.string :cycle_label, null: false
      t.date :window_start, null: false
      t.date :window_end, null: false
      t.datetime :closed_at, null: false
      t.integer :level_position_at_close, null: false
      t.integer :target_level_position, null: false
      t.json :met, null: false, default: []
      t.json :gap, null: false, default: []
      t.text :narrative
      t.json :prompt_payload

      t.timestamps
    end

    add_index :snapshots, [:person_id, :cycle_label], unique: true
  end
end
