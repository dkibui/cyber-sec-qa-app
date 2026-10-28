require "test_helper"
require_relative "../support/evidence_helper"

class DecisionsTest < ActionDispatch::IntegrationTest
  include EvidenceHelper

  setup do
    domain = Domain.create!(name: "Authentication")
    domain.controls.create!(description: "Every request is authenticated", default_severity: :critical)
    @project = Project.create!(name: "Demo")
    @assessment = @project.submit!
    @result = @assessment.control_results.first
  end

  test "a forward is refused while a control is still pending" do
    sign_in_as user(:security_tester)
    post assessment_decision_url(@assessment, outcome: "forward")
    assert_redirected_to assessment_url(@assessment)
    assert @project.reload.design_review?
    assert @assessment.reload.outcome_in_progress?
  end

  test "a tester can forward a clean assessment" do
    @result.update!(status: :passed)
    sign_in_as user(:security_tester)
    post assessment_decision_url(@assessment, outcome: "forward")
    assert @project.reload.development?
  end

  test "a developer cannot decide" do
    @result.update!(status: :passed)
    sign_in_as user(:developer)
    post assessment_decision_url(@assessment, outcome: "forward")
    assert @project.reload.design_review?
  end

  test "only a tester can record an override" do
    @result.update!(status: :failed)
    sign_in_as user(:admin)
    post assessment_override_url(@assessment), params: { override: { comments: "Patch next week" } }
    assert_nil @assessment.reload.override

    sign_in_as user(:security_tester)
    post assessment_override_url(@assessment), params: { override: { comments: "Patch next week" } }
    assert_equal "Patch next week", @assessment.reload.override.comments
  end

  private

  def user(role)
    User.find_or_create_by!(email_address: "#{role}@example.com") { |u| u.password = "password123"; u.role = role }
  end
end
