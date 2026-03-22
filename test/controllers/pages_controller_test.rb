require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "auth page is public" do
    get new_user_session_url
    assert_response :success
  end

  test "protected pages require authentication" do
    get root_url
    assert_redirected_to new_user_session_url
  end

  test "authenticated user can open settings and update account/profile" do
    sign_in users(:one)

    get settings_url
    assert_response :success

    patch settings_account_url, params: { user: { username: "new_login", name: "New Name", email: "new@example.com" } }
    assert_redirected_to settings_url
    users(:one).reload
    assert_equal "new_login", users(:one).username
    assert_equal "new@example.com", users(:one).email

    patch settings_profile_url, params: { user: { name: "Profile Name", bio: "Updated bio" } }
    assert_redirected_to settings_url(anchor: "profile-section")
    users(:one).reload
    assert_equal "Profile Name", users(:one).name
    assert_equal "Updated bio", users(:one).bio
  end
end
