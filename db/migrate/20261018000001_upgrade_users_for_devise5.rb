# Devise 5 stores the bcrypt salt inside encrypted_password and keeps remember
# state in remember_created_at, so the Devise 1.1 columns are dropped.
# :recoverable now needs reset_password_sent_at.
class UpgradeUsersForDevise5 < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :reset_password_sent_at, :datetime
    remove_column :users, :password_salt, :string, default: "", null: false
    remove_column :users, :remember_token, :string
  end
end
