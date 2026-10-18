# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_10_19_150001) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "finance_entries", force: :cascade do |t|
    t.integer "note_id", null: false
    t.date "date"
    t.decimal "amount", precision: 12, scale: 2, null: false
    t.string "comment"
    t.string "author"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["note_id"], name: "index_finance_entries_on_note_id"
  end

  create_table "note_attachments", force: :cascade do |t|
    t.integer "note_id", null: false
    t.string "comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["note_id"], name: "index_note_attachments_on_note_id"
  end

  create_table "note_versions", force: :cascade do |t|
    t.integer "note_id", null: false
    t.string "event", null: false
    t.string "title", null: false
    t.text "description"
    t.string "color", null: false
    t.string "author"
    t.string "details"
    t.datetime "created_at", null: false
    t.index ["note_id", "created_at"], name: "index_note_versions_on_note_id_and_created_at"
  end

  create_table "notes", force: :cascade do |t|
    t.string "title", null: false
    t.text "description"
    t.date "visited_on"
    t.boolean "active", default: true, null: false
    t.boolean "closed", default: false, null: false
    t.string "author"
    t.string "updated_from"
    t.string "couchdb_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "note_attachments_count", default: 0, null: false
    t.string "share_token"
    t.string "share_password_digest"
    t.datetime "shared_at"
    t.string "color", default: "yellow", null: false
    t.boolean "markdown", default: false, null: false
    t.boolean "wide", default: false, null: false
    t.index ["couchdb_id"], name: "index_notes_on_couchdb_id", unique: true
    t.index ["share_token"], name: "index_notes_on_share_token", unique: true
    t.index ["title"], name: "index_notes_on_title", unique: true
  end

  create_table "taggings", force: :cascade do |t|
    t.integer "note_id", null: false
    t.integer "tag_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["note_id", "tag_id"], name: "index_taggings_on_note_id_and_tag_id", unique: true
    t.index ["note_id"], name: "index_taggings_on_note_id"
    t.index ["tag_id"], name: "index_taggings_on_tag_id"
  end

  create_table "tags", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_tags_on_name", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email"
    t.string "encrypted_password", limit: 128, default: "", null: false
    t.string "reset_password_token"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "username"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "reset_password_sent_at"
    t.boolean "admin", default: false, null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "finance_entries", "notes"
  add_foreign_key "note_attachments", "notes"
  add_foreign_key "note_versions", "notes"
  add_foreign_key "taggings", "notes"
  add_foreign_key "taggings", "tags"
end
