require "test_helper"

class ControlLibraryImportTest < ActiveSupport::TestCase
  def csv(*rows)
    header = "ID,Control / Test Description,OWASP / Ref,CWE / NIST,Status,Severity,Comments / Findings,Owner"
    [ "API CONTROLS — LOOP APIs", header, *rows ].join("\n")
  end

  # Domain 1 has ten controls, and the tenth is written "1.1" as Excel corrupted it.
  def sample
    controls = (1..9).map { |n| "1.#{n},Authentication control #{n},API2:2023,CWE-306,Passed,High,Core APIs,Owner" }
    controls << "1.1,Authentication control 10,API2:2023,CWE-287,Failed,Critical,Core APIs,Owner"
    csv("1.0 AUTHENTICATION,,,,,,,", *controls,
        "9.0 API INVENTORY,,,,,,,",
        "9.1,Keep an API inventory,API9:2023,CWE-1059,Passed,Low,Core APIs,Owner")
  end

  test "reads domains and controls without saving anything" do
    plan = ControlLibraryImport.new(sample)
    assert_equal [ "Authentication", "API Inventory" ], plan.sections.map(&:name)
    assert_equal 11, plan.new_controls
    assert_equal 0, Domain.count
    assert_equal 0, Control.count
  end

  test "reads the second 1.1 as 1.10 and says so" do
    plan = ControlLibraryImport.new(sample)
    assert_equal "1.10", plan.sections.first.entries.last.ref
    assert(plan.warnings.any? { |w| w.include?("1.10") })
  end

  test "numbers domains by order, not by the heading" do
    plan = ControlLibraryImport.new(sample)
    assert_equal 2, plan.sections.last.number
    assert(plan.warnings.any? { |w| w.include?("numbered 2") })
  end

  test "importing twice creates no duplicates" do
    assert_equal 11, ControlLibraryImport.new(sample).commit!
    second = ControlLibraryImport.new(sample)
    assert_equal 0, second.new_controls
    assert_equal 11, second.existing_controls
    assert_not second.importable?
    assert_equal 11, Control.count
    assert_equal 2, Domain.count
  end

  test "existing controls are left alone and new ones take the next free number" do
    domain = Domain.create!(name: "Authentication")
    existing = Control.create!(domain: domain, description: "Authentication control 1", default_severity: :low)
    plan = ControlLibraryImport.new(sample)
    assert_equal 1, plan.sections.first.entries.count(&:existing)
    assert_equal "1.2", plan.sections.first.entries.find { |e| !e.existing }.ref
    plan.commit!
    assert_equal "low", existing.reload.default_severity
  end

  test "a file without a header row is rejected" do
    assert ControlLibraryImport.new("a,b\n1,2").errors.any?
  end
end
