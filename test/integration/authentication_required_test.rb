require "test_helper"

class AuthenticationRequiredTest < ActionDispatch::IntegrationTest
  test "visitors are sent to the sign-in page" do
    get root_url
    assert_redirected_to new_session_url
  end
end
