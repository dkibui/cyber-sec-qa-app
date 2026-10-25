require "test_helper"

class AssessmentTest < ActiveSupport::TestCase
  setup do
    @domain = Domain.create!(name: "Authentication")
    @critical = @domain.controls.create!(description: "Every request is authenticated", default_severity: :critical)
    @high = @domain.controls.create!(description: "MFA where risk warrants it", default_severity: :high)
    @project = Project.create!(name: "Demo")
  end

  test "submitting a design starts a design-gate assessment at round 1" do
    assessment = @project.submit!
    assert @project.reload.design_review?
    assert assessment.gate_design?
    assert_equal 1, assessment.round
    assert assessment.outcome_in_progress?
  end

  test "submitting a build starts a testing-gate assessment" do
    @project.update!(stage: :development)
    assessment = @project.submit!
    assert @project.reload.security_testing?
    assert assessment.gate_testing?
  end

  test "an assessment starts with a pending result for every active control" do
    assessment = @project.submit!
    assert_equal 2, assessment.control_results.count
    assert assessment.control_results.all?(&:status_pending?)
    assert_equal "critical", assessment.control_results.find_by(control: @critical).severity
  end

  test "retired controls are left out of new assessments" do
    @high.retire!
    assessment = @project.submit!
    assert_equal [ @critical.id ], assessment.control_results.pluck(:control_id)
  end

  test "a project that is under review or live cannot be submitted" do
    @project.submit!
    assert_raises(Project::InvalidTransition) { @project.reload.submit! }
    @project.update!(stage: :live)
    assert_raises(Project::InvalidTransition) { @project.submit! }
  end

  test "a round number is unique per project and gate" do
    @project.submit!
    duplicate = @project.assessments.build(gate: :design, round: 1)
    assert_not duplicate.valid?
  end

  test "requires_evidence? is true for failed and partial results only" do
    result = @project.submit!.control_results.first
    { pending: false, passed: false, not_applicable: false, failed: true, partial: true }.each do |status, expected|
      result.status = status
      assert_equal expected, result.requires_evidence?, status.to_s
    end
  end
end
