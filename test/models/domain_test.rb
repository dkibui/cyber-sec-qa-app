require "test_helper"

class DomainTest < ActiveSupport::TestCase
  test "numbers are assigned in sequence" do
    assert_equal 1, Domain.create!(name: "Authentication").number
    assert_equal 2, Domain.create!(name: "Authorization").number
  end

  test "an explicit number is kept, and the next one follows it" do
    Domain.create!(name: "Authentication", number: 5)
    assert_equal 6, Domain.create!(name: "Authorization").number
  end

  test "name and number are unique" do
    Domain.create!(name: "Authentication")
    assert_not Domain.new(name: "Authentication").valid?
    assert_not Domain.new(name: "Other", number: 1).valid?
  end

  test "a name is required" do
    assert_not Domain.new.valid?
  end
end
