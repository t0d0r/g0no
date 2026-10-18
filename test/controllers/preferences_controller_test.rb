require "test_helper"

class PreferencesControllerTest < ActionDispatch::IntegrationTest
  test "remembers the theme and text size without sign in" do
    patch preferences_url, params: { theme: "dark" }, headers: { "Referer" => new_user_session_url }
    assert_redirected_to new_user_session_url
    patch preferences_url, params: { scale: "extra" }

    get new_user_session_url
    assert_select "html[data-theme=dark][data-scale=extra]"
    assert_select "button[name=scale][value=extra][aria-pressed=true]"
  end

  test "ignores unknown values" do
    patch preferences_url, params: { theme: "neon", scale: "huge" }
    get new_user_session_url
    assert_select "html[data-theme=''][data-scale=normal]"
  end

  test "the menu bar has the theme switch and text sizes" do
    sign_in users(:admin)
    get notes_url
    assert_select ".menubar form.prefs button[name=theme][value=dark]"
    assert_select ".menubar form.prefs button[name=theme][value=light]"
    assert_select ".menubar form.prefs button[name=scale]", 3
  end
end
