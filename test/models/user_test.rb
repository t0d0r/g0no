require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "finds a user by username or email, ignoring case" do
    admin = users(:admin)
    assert_equal admin, User.find_for_database_authentication(email: "admin")
    assert_equal admin, User.find_for_database_authentication(email: "admin@example.com")
    assert_equal admin, User.find_for_database_authentication(email: "ADMIN")
    assert_nil User.find_for_database_authentication(email: "nobody")
  end

  test "display_name prefers the username" do
    assert_equal "admin", users(:admin).display_name
    assert_equal "x@example.com", User.new(email: "x@example.com", username: "").display_name
  end

  test "verifies password hashes created by Devise 1.1 with a pepper" do
    pepper = "legacy-pepper"
    salt = BCrypt::Engine.generate_salt(10)
    # Devise 1.1's bcrypt encryptor: hash_secret(password + pepper, salt, stretches)
    legacy_hash = BCrypt::Engine.hash_secret("secret123#{pepper}", salt)
    user = User.new(email: "old@example.com", encrypted_password: legacy_hash)

    original = Devise.pepper
    Devise.pepper = pepper
    assert user.valid_password?("secret123")
    assert_not user.valid_password?("wrong")
  ensure
    Devise.pepper = original
  end
end
