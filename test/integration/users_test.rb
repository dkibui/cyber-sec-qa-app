require "test_helper"

class UsersTest < ActionDispatch::IntegrationTest
  def user(role)
    User.find_or_create_by!(email_address: "#{role}@example.com") { |u| u.password = "password123"; u.role = role }
  end

  test "admin creates a user with a role" do
    sign_in_as user(:admin)
    post users_url, params: { user: { email_address: "new.dev@example.com", role: "developer", password: "password123" } }
    assert_redirected_to users_url
    assert User.find_by(email_address: "new.dev@example.com").developer?
  end

  test "admin cannot remove their own admin role" do
    admin = user(:admin)
    sign_in_as admin
    patch user_url(admin), params: { user: { role: "reviewer" } }
    assert admin.reload.admin?
  end

  test "other roles cannot manage users" do
    %i[architect developer security_tester reviewer].each do |role|
      sign_in_as user(role)
      post users_url, params: { user: { email_address: "x-#{role}@example.com", role: "admin", password: "password123" } }
      assert_nil User.find_by(email_address: "x-#{role}@example.com"), "#{role} should not create users"
    end
  end
end
