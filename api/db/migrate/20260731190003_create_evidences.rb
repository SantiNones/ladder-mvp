class CreateEvidences < ActiveRecord::Migration[8.1]
  def change
    create_table :evidences do |t|
      t.integer :person_id, null: false
      t.integer :criterion_id, null: false
      t.integer :author_id, null: false
      t.string :author_relation, null: false
      t.string :source_type, null: false
      t.text :body, null: false
      t.date :occurred_on, null: false

      t.timestamps
    end

    add_index :evidences, :person_id
    add_index :evidences, :criterion_id
    add_index :evidences, :author_id
    add_foreign_key :evidences, :people, column: :person_id
    add_foreign_key :evidences, :criteria, column: :criterion_id
    add_foreign_key :evidences, :people, column: :author_id
  end
end
