class AddSharingToNotes < ActiveRecord::Migration[8.1]
  def change
    add_column :notes, :share_token, :string
    add_column :notes, :share_password_digest, :string
    add_column :notes, :shared_at, :datetime
    add_index :notes, :share_token, unique: true
  end
end
