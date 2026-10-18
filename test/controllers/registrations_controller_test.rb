require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  def with_registration(open)
    previous = Rails.configuration.x.registration_open
    Rails.configuration.x.registration_open = open
    yield
  ensure
    Rails.configuration.x.registration_open = previous
  end

  test "open sign-up shows the form and creates a user" do
    with_registration(true) do
      get new_user_session_url
      assert_select "a[href=?]", new_user_registration_path

      get new_user_registration_url
      assert_response :success

      assert_difference "User.count", 1 do
        post user_registration_url, params: { user: { username: "rincewind", email: "rincewind@example.com",
                                                      password: "octarine1", password_confirmation: "octarine1" } }
      end
    end
  end

  test "closed sign-up hides the link and refuses new accounts" do
    with_registration(false) do
      get new_user_session_url
      assert_select "a[href=?]", new_user_registration_path, count: 0

      get new_user_registration_url
      assert_redirected_to new_user_session_url

      assert_no_difference "User.count" do
        post user_registration_url, params: { user: { username: "rincewind", email: "rincewind@example.com",
                                                      password: "octarine1", password_confirmation: "octarine1" } }
      end
      assert_redirected_to new_user_session_url
      follow_redirect!
      assert_match "Sign-up is closed", response.body
    end
  end

  test "closed sign-up still lets a user edit their own account" do
    with_registration(false) do
      sign_in users(:admin)
      get edit_user_registration_url
      assert_response :success
    end
  end
end
