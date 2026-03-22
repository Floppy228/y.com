require "test_helper"
require "cgi"

class AuthenticationFlowTest < ActionDispatch::IntegrationTest
  test "guest is redirected to /auth from protected page" do
    get root_url
    assert_redirected_to new_user_session_url
  end

  test "user can sign in and sign out with custom auth routes" do
    post user_session_path, params: { user: { email: users(:one).email, password: "password123" } }
    assert_redirected_to root_url

    follow_redirect!
    assert_response :success

    delete destroy_user_session_path
    assert_redirected_to new_user_session_url
  end

  test "invalid password does not authenticate user" do
    post user_session_path, params: { user: { email: users(:one).email, password: "wrong_password" } }
    assert_response :unprocessable_entity
  end

  test "duplicate registration is rejected" do
    assert_no_difference("User.count") do
      post user_registration_path, params: {
        user: {
          email: "ONE@EXAMPLE.COM",
          password: "password123",
          password_confirmation: "password123",
          name: "Duplicate",
          username: "ONE_USER"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_match(/already been taken/i, response.body)
  end

  test "new user can register and gets signed in" do
    assert_difference("User.count", 1) do
      post user_registration_path, params: {
        user: {
          email: "new_user@example.com",
          password: "password123",
          password_confirmation: "password123",
          name: "New User",
          username: "new_user_1"
        }
      }
    end

    assert_redirected_to root_url
  end

  test "user can reset password via email token" do
    ActionMailer::Base.deliveries.clear
    user = users(:one)

    post user_password_path, params: { user: { email: user.email } }
    assert_redirected_to new_user_session_url
    assert_equal 1, ActionMailer::Base.deliveries.size

    message = ActionMailer::Base.deliveries.last
    assert_includes Array(message.to), user.email

    token_match = message.body.encoded.match(/reset_password_token=([^"&]+)/)
    assert token_match
    reset_token = CGI.unescape(token_match[1])

    get edit_user_password_path(reset_password_token: reset_token)
    assert_response :success

    put user_password_path, params: {
      user: {
        reset_password_token: reset_token,
        password: "newpassword123",
        password_confirmation: "newpassword123"
      }
    }
    assert_redirected_to root_url

    delete destroy_user_session_path
    post user_session_path, params: { user: { email: user.email, password: "newpassword123" } }
    assert_redirected_to root_url
  end
end
