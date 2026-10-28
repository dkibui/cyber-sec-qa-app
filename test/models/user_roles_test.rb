require "test_helper"

class UserRolesTest < ActiveSupport::TestCase
  def build_user(role = nil)
    User.create!(email_address: "#{role || 'new'}@example.com", password: "password123", **{ role: role }.compact)
  end

  test "new users default to the read-only reviewer role" do
    user = build_user
    assert user.reviewer?
    assert_not user.can_test?
    assert_not user.can_manage_library?
  end

  test "only a security tester records results" do
    assert build_user(:security_tester).can_test?
    assert_not build_user(:developer).can_test?
  end

  test "only a security tester records overrides" do
    assert build_user(:security_tester).can_approve_override?
    assert_not build_user(:admin).can_approve_override?
  end

  test "only the admin manages the library, users and projects" do
    admin = build_user(:admin)
    assert admin.can_manage_library?
    assert admin.can_manage_users?
    assert admin.can_create_project?
    assert_not admin.can_test?

    assert_not build_user(:security_tester).can_manage_library?
    assert_not build_user(:architect).can_create_project?
  end

  test "an unknown role is invalid" do
    assert_not User.new(email_address: "x@example.com", password: "password123", role: "wizard").valid?
  end
end
