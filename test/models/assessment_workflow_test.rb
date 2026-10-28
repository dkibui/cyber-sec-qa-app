require "test_helper"
require_relative "../support/evidence_helper"

class AssessmentWorkflowTest < ActiveSupport::TestCase
  include EvidenceHelper

  setup do
    @domain = Domain.create!(name: "Authentication")
    @critical = @domain.controls.create!(description: "Every request is authenticated", default_severity: :critical)
    @high = @domain.controls.create!(description: "MFA where risk warrants it", default_severity: :high)
    @project = Project.create!(name: "Demo")
    @tester = User.create!(email_address: "tester-test@example.com", password: "password123", role: :security_tester)
  end

  test "cannot forward while a control is pending" do
    assessment = @project.submit!
    error = assert_raises(Assessment::NotReady) { assessment.forward! }
    assert_match(/Pending/, error.message)
  end

  test "failed or partial controls need a finding with evidence before forwarding" do
    assessment = @project.submit!
    results = assessment.control_results.index_by(&:control_id)
    results[@critical.id].update!(status: :passed)
    results[@high.id].update!(status: :partial)

    error = assert_raises(Assessment::NotReady) { assessment.forward! }
    assert_match(/Evidence is missing/, error.message)

    add_evidence(results[@high.id])
    assessment.forward!
    assert @project.reload.development?
  end

  test "forwarding at the testing gate takes the project live" do
    @project.update!(stage: :development)
    assessment = @project.submit!
    assessment.control_results.update_all(status: ControlResult.statuses[:passed])
    assessment.forward!
    assert @project.reload.live?
  end

  test "an open critical failure needs a tester override with comments" do
    assessment = @project.submit!
    results = assessment.control_results.index_by(&:control_id)
    results[@critical.id].update!(status: :failed)
    results[@high.id].update!(status: :passed)
    add_evidence(results[@critical.id])

    error = assert_raises(Assessment::NotReady) { assessment.forward! }
    assert_match(/Critical/, error.message)

    assert_not Override.new(assessment: assessment, approver: @tester, comments: "").valid?
    Override.create!(assessment: assessment, approver: @tester, comments: "Patch scheduled for Friday")
    assessment.reload.forward!
    assert @project.reload.development?
  end

  test "only a tester can record an override" do
    assessment = @project.submit!
    admin = User.create!(email_address: "admin-test@example.com", password: "password123", role: :admin)
    assert_not Override.new(assessment: assessment, approver: admin, comments: "ok").valid?
  end

  test "returning sends the project back and the next submission is round 2" do
    assessment = @project.submit!
    assessment.control_results.find_by(control: @critical).update!(status: :failed)
    assessment.return!
    assert @project.reload.design?
    assert_equal "Solutions architect", assessment.returned_to

    second = @project.submit!
    assert_equal 2, second.round
    assert assessment.reload.outcome_returned?, "earlier rounds stay as history"
  end

  test "cannot return when nothing failed" do
    assessment = @project.submit!
    assert_raises(Assessment::NotReady) { assessment.return! }
  end

  test "a decided assessment cannot be decided again" do
    @project.update!(stage: :development)
    assessment = @project.submit!
    assessment.control_results.update_all(status: ControlResult.statuses[:passed])
    assessment.forward!
    assert_raises(Assessment::NotReady) { assessment.forward! }
  end
end
