require "test_helper"

class SeedsTest < ActiveSupport::TestCase
  SEEDS = Rails.root.join("db/seeds.rb")

  def run_seeds(env)
    keys = %w[ADMIN_EMAIL ADMIN_PASSWORD ADMIN_USERNAME]
    saved = keys.to_h { |key| [ key, ENV[key] ] }
    keys.each { |key| ENV[key] = env[key] }
    capture_io { load SEEDS }.first
  ensure
    saved.each { |key, value| ENV[key] = value }
  end

  test "creates the admin user when it is missing, even if other users exist" do
    User.where(username: "admin").delete_all
    User.create!(email: "other@example.com", password: "password", username: "other")

    out = run_seeds("ADMIN_EMAIL" => "boss@example.com", "ADMIN_PASSWORD" => "s3cret-pass")

    admin = User.find_by!(username: "admin")
    assert_equal "boss@example.com", admin.email
    assert admin.valid_password?("s3cret-pass")
    assert admin.admin?
    assert_match "created user 'admin'", out
    assert_no_match "s3cret-pass", out
  end

  test "leaves an existing admin user unchanged" do
    out = run_seeds("ADMIN_EMAIL" => "new@example.com", "ADMIN_PASSWORD" => "another-pass")

    assert users(:admin).reload.valid_password?("password")
    assert_match "already exists", out
  end

  test "marks an existing user with the admin username as administrator" do
    users(:admin).update_column(:admin, false)
    out = run_seeds("ADMIN_EMAIL" => "new@example.com", "ADMIN_PASSWORD" => "another-pass")

    admin = users(:admin).reload
    assert admin.admin?
    assert_equal "admin@example.com", admin.email
    assert admin.valid_password?("password")
    assert_match "marked as administrator", out
  end

  test "uses ADMIN_USERNAME" do
    run_seeds("ADMIN_EMAIL" => "ops@example.com", "ADMIN_PASSWORD" => "s3cret-pass", "ADMIN_USERNAME" => "ops")
    assert User.exists?(username: "ops", email: "ops@example.com")
  end

  test "skips without credentials" do
    User.where(username: "admin").delete_all
    out = run_seeds({})
    assert_not User.exists?(username: "admin")
    assert_match "skipped", out
  end
end
