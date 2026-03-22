require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "valid fixture user is valid" do
    assert users(:one).valid?
  end

  test "username is normalized before validation" do
    user = User.new(
      email: "normalize@example.com",
      password: "password123",
      password_confirmation: "password123",
      name: "Normalize User",
      username: "@My_Name"
    )

    assert user.valid?
    assert_equal "my_name", user.username
  end

  test "bio is limited to 160 characters" do
    user = users(:one)
    user.bio = "a" * 161

    assert_not user.valid?
  end

  test "email uniqueness is case-insensitive" do
    user = User.new(
      email: "ONE@EXAMPLE.COM",
      password: "password123",
      password_confirmation: "password123",
      name: "Duplicate Email",
      username: "unique_name_1"
    )

    assert_not user.valid?
    assert_includes user.errors[:email], "has already been taken"
  end

  test "username uniqueness is case-insensitive" do
    user = User.new(
      email: "unique_case@example.com",
      password: "password123",
      password_confirmation: "password123",
      name: "Duplicate Username",
      username: "ONE_USER"
    )

    assert_not user.valid?
    assert_includes user.errors[:username], "has already been taken"
  end
end
