# Notes used to live in CouchDB as one document each. See specs/data-model.md
# for how the document fields map to these tables.
class CreateNotes < ActiveRecord::Migration[8.1]
  def change
    create_table :notes do |t|
      t.string  :title, null: false
      t.text    :description
      t.date    :visited_on
      t.boolean :active, null: false, default: true
      t.boolean :closed, null: false, default: false
      t.string  :author
      t.string  :updated_from
      t.string  :couchdb_id

      t.timestamps
    end
    add_index :notes, :title, unique: true
    add_index :notes, :couchdb_id, unique: true

    create_table :tags do |t|
      t.string :name, null: false

      t.timestamps
    end
    add_index :tags, :name, unique: true

    create_table :taggings do |t|
      t.references :note, null: false, foreign_key: true
      t.references :tag, null: false, foreign_key: true

      t.timestamps
    end
    add_index :taggings, [ :note_id, :tag_id ], unique: true

    create_table :finance_entries do |t|
      t.references :note, null: false, foreign_key: true
      t.date    :date
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.string  :comment
      t.string  :author

      t.timestamps
    end

    create_table :note_attachments do |t|
      t.references :note, null: false, foreign_key: true
      t.string :comment

      t.timestamps
    end
  end
end
