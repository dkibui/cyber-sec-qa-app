require "test_helper"

class ProjectTest < ActiveSupport::TestCase
  test "a new project starts at design" do
    assert Project.create!(name: "Demo").design?
  end

  test "a name is required" do
    assert_not Project.new.valid?
  end

  test "an unknown stage is invalid" do
    assert_not Project.new(name: "Demo", stage: "launched").valid?
  end

  test "architect and developer are optional users" do
    architect = User.create!(email_address: "arch@example.com", password: "password123", role: :architect)
    project = Project.create!(name: "Demo", architect: architect)
    assert_equal architect, project.architect
    assert_nil project.developer
  end
end
