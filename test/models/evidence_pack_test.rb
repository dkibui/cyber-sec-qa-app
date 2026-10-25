require "test_helper"
require_relative "../support/evidence_helper"

class EvidencePackTest < ActiveSupport::TestCase
  include EvidenceHelper

  setup do
    domain = Domain.create!(name: "Authentication")
    @critical = domain.controls.create!(description: "Every request is authenticated", default_severity: :critical)
    @high = domain.controls.create!(description: "MFA where risk warrants it", default_severity: :high)
    @assessment = Project.create!(name: "Demo").submit!
    @results = @assessment.control_results.index_by(&:control_id)
  end

  test "a finding must belong to a result in the same assessment" do
    other = Project.create!(name: "Other").submit!
    finding = @assessment.findings.build(control_result: other.control_results.first, category: "x")
    assert_not finding.valid?
  end

  test "evidence needs a caption and an attached file" do
    finding = @assessment.findings.create!(control_result: @results[@critical.id], category: "AuthN")
    assert_not finding.evidences.build(caption: "").valid?
    assert_not finding.evidences.build(caption: "Figure 1").valid?, "file is required"
  end

  test "only images and PDFs are accepted as evidence" do
    finding = @assessment.findings.create!(control_result: @results[@critical.id], category: "AuthN")
    evidence = finding.evidences.build(caption: "Notes")
    evidence.file.attach(io: StringIO.new("hello"), filename: "notes.txt", content_type: "text/plain")
    assert_not evidence.valid?
    assert_includes evidence.errors[:file].join, "PNG, JPEG"
  end

  test "a failed control is missing evidence until a finding has a screenshot" do
    result = @results[@critical.id]
    result.update!(status: :failed)
    assert_equal [ result ], @assessment.missing_evidence

    @assessment.findings.create!(control_result: result, category: "AuthN")
    assert_equal [ result ], @assessment.reload.missing_evidence, "a finding without evidence is not enough"

    add_evidence(result)
    assert_empty @assessment.reload.missing_evidence
  end

  test "partial counts as a vulnerability, passed does not" do
    @results[@high.id].update!(status: :partial)
    @results[@critical.id].update!(status: :passed)
    assert_equal [ @results[@high.id] ], @assessment.missing_evidence
  end

  test "ready_for_decision? needs no pending controls and no missing evidence" do
    assert_not @assessment.ready_for_decision?
    @assessment.control_results.update_all(status: ControlResult.statuses[:passed])
    assert @assessment.reload.ready_for_decision?
  end

  test "open_critical_count counts failed or partial critical controls" do
    @results[@critical.id].update!(status: :failed)
    @results[@high.id].update!(status: :failed)
    assert_equal 1, @assessment.open_critical_count
  end
end
