require "test_helper"

class AdminControllerTest < ActionDispatch::IntegrationTest
  test "only administrators open the admin panel" do
    sign_in users(:bob)
    get admin_root_url
    assert_redirected_to root_url
    get new_admin_user_url
    assert_redirected_to root_url
  end

  test "the admin panel needs sign in" do
    get admin_root_url
    assert_redirected_to new_user_session_url
  end

  test "the menu bar links to the admin panel for administrators only" do
    sign_in users(:bob)
    get notes_url
    assert_select ".menubar a[href=?]", admin_root_path, 0

    sign_in users(:admin)
    get notes_url
    assert_select ".menubar a.nav-link[href=?]:not([aria-current])", admin_root_path
    assert_select ".menubar a.nav-link[href=?][aria-current=page]", notes_path
    get admin_root_url
    assert_select ".menubar a.nav-link[href=?][aria-current=page]", admin_root_path
  end

  test "lists users and stats" do
    sign_in users(:admin)
    get admin_root_url
    assert_response :success
    assert_select ".table-users tbody tr", 2
    assert_select "#user_#{users(:admin).id} .tag-pill"
    assert_select ".stat", 5
  end

  test "creates a user" do
    sign_in users(:admin)
    assert_difference("User.count") do
      post admin_users_url, params: { user: { username: "carol", email: "carol@example.com",
                                              password: "s3cret-pass", password_confirmation: "s3cret-pass", admin: "0" } }
    end
    assert_redirected_to admin_root_url
    assert_not User.find_by!(username: "carol").admin?
  end

  test "rejects a duplicate username" do
    sign_in users(:admin)
    assert_no_difference("User.count") do
      post admin_users_url, params: { user: { username: "BOB", email: "b2@example.com",
                                              password: "s3cret-pass", password_confirmation: "s3cret-pass" } }
    end
    assert_response :unprocessable_content
  end

  test "updates a user and keeps the password when it is blank" do
    sign_in users(:admin)
    bob = users(:bob)
    patch admin_user_url(bob), params: { user: { email: "robert@example.com", password: "", password_confirmation: "", admin: "1" } }
    assert_redirected_to admin_root_url
    bob.reload
    assert_equal "robert@example.com", bob.email
    assert bob.admin?
    assert bob.valid_password?("password")
  end

  test "sets a new password" do
    sign_in users(:admin)
    patch admin_user_url(users(:bob)), params: { user: { password: "new-pass-123", password_confirmation: "new-pass-123" } }
    assert users(:bob).reload.valid_password?("new-pass-123")
  end

  test "an administrator cannot remove their own admin flag or delete themselves" do
    admin = users(:admin)
    sign_in admin
    patch admin_user_url(admin), params: { user: { admin: "0" } }
    assert admin.reload.admin?

    assert_no_difference("User.count") { delete admin_user_url(admin) }
    assert_redirected_to admin_root_url
  end

  test "an administrator stays signed in after changing their own password" do
    admin = users(:admin)
    sign_in admin
    patch admin_user_url(admin), params: { user: { password: "new-pass-123", password_confirmation: "new-pass-123" } }
    get admin_root_url
    assert_response :success
  end

  test "deletes another user" do
    sign_in users(:admin)
    assert_difference("User.count", -1) { delete admin_user_url(users(:bob)) }
  end

  test "lists and revokes shared notes" do
    note = notes(:groceries)
    note.share(password: "open-sesame")
    sign_in users(:admin)
    get admin_root_url
    assert_select "#share_note_#{note.id}"
    delete admin_share_url(note)
    assert_nil note.reload.share_token
  end
end
