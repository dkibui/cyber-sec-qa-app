require "test_helper"

class RecordingResultsTest < ActionDispatch::IntegrationTest
  setup do
    domain = Domain.create!(name: "Authentication")
    domain.controls.create!(description: "Every request is authenticated", default_severity: :critical)
    @assessment = Project.create!(name: "Demo").submit!
    @result = @assessment.control_results.first
  end

  test "a security tester can record a result" do
    sign_in_as user(:security_tester)
    patch control_result_url(@result), params: { control_result: { status: "failed", comments: "No auth header", owner: "OMarion" } }
    assert_response :redirect
    @result.reload
    assert @result.status_failed?
    assert_equal "No auth header", @result.comments
    assert_equal "OMarion", @result.owner
  end

  test "the first result recorded assigns the tester to the assessment" do
    tester = user(:security_tester)
    sign_in_as tester
    patch control_result_url(@result), params: { control_result: { status: "passed" } }
    assert_equal tester, @assessment.reload.tester
  end

  test "a reviewer cannot record a result" do
    sign_in_as user(:reviewer)
    patch control_result_url(@result), params: { control_result: { status: "passed" } }
    assert @result.reload.status_pending?
  end

  test "a developer cannot record a result" do
    sign_in_as user(:developer)
    patch control_result_url(@result), params: { control_result: { status: "passed" } }
    assert @result.reload.status_pending?
  end

  test "an unknown status is refused, not a server error" do
    sign_in_as user(:security_tester)
    patch control_result_url(@result), params: { control_result: { status: "bogus" } }
    assert_response :redirect
    assert @result.reload.status_pending?
  end

  test "a decided assessment cannot be changed" do
    @assessment.update!(outcome: :returned)
    sign_in_as user(:security_tester)
    patch control_result_url(@result), params: { control_result: { status: "passed" } }
    assert @result.reload.status_pending?
  end

  private

  def user(role)
    User.create!(email_address: "#{role}@example.com", password: "password123", role: role)
  end
end
