require "test_helper"

class ControlTest < ActiveSupport::TestCase
  setup do
    @domain = Domain.create!(name: "Authentication")
    @first = @domain.controls.create!(description: "Every request is authenticated", default_severity: :critical)
    @second = @domain.controls.create!(description: "MFA where risk warrants it")
  end

  test "the ref is derived from the domain number and the control sequence" do
    assert_equal "1.1", @first.ref
    assert_equal "1.2", @second.ref
  end

  test "sequence numbers stay correct past nine, with no text confusion between 1.1 and 1.10" do
    8.times { |i| @domain.controls.create!(description: "Control #{i}") }
    tenth = @domain.controls.create!(description: "Tenth")
    assert_equal "1.11", tenth.ref
    assert_equal [ 1, 2 ], @domain.controls.first(2).map(&:sequence)
  end

  test "a retired control's number is never reused" do
    @second.retire!
    assert @second.retired?
    assert_equal "1.3", @domain.controls.create!(description: "New control").ref
  end

  test "active excludes retired controls and restore brings them back" do
    @second.retire!
    assert_equal [ @first ], Control.active.to_a
    @second.restore!
    assert_equal 2, Control.active.count
  end

  test "a description is required and severity must be known" do
    assert_not @domain.controls.build.valid?
    assert_raises(ArgumentError) { @domain.controls.build(description: "x", default_severity: :urgent) }
  end
end
