require "test_helper"
require_relative "../support/evidence_helper"

class EvidenceUploadTest < ActionDispatch::IntegrationTest
  setup do
    domain = Domain.create!(name: "Authentication")
    domain.controls.create!(description: "Every request is authenticated", default_severity: :critical)
    @assessment = Project.create!(name: "Demo").submit!
    @result = @assessment.control_results.first
    @result.update!(status: :failed)
  end

  test "a tester can log a finding and upload evidence" do
    sign_in_as user(:security_tester)
    post assessment_findings_url(@assessment), params: { finding: { control_result_id: @result.id, category: "AuthN", test_objective: "x", observations: "y" } }
    finding = Finding.last
    assert_redirected_to finding_url(finding)

    upload = Rack::Test::UploadedFile.new(StringIO.new(EvidenceHelper::PNG), "image/png", original_filename: "shot.png")
    post finding_evidences_url(finding), params: { evidence: { caption: "Figure 1", file: upload } }
    assert_equal 1, finding.reload.evidences.count
    assert @result.reload.evidence_complete?
  end

  test "a reviewer cannot log findings" do
    sign_in_as user(:reviewer)
    assert_no_difference "Finding.count" do
      post assessment_findings_url(@assessment), params: { finding: { control_result_id: @result.id, category: "AuthN" } }
    end
  end

  test "findings cannot be added once the assessment is decided" do
    @assessment.update!(outcome: :returned)
    sign_in_as user(:security_tester)
    assert_no_difference "Finding.count" do
      post assessment_findings_url(@assessment), params: { finding: { control_result_id: @result.id, category: "AuthN" } }
    end
  end

  private

  def user(role)
    User.create!(email_address: "#{role}@example.com", password: "password123", role: role)
  end
end
