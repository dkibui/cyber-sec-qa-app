require "test_helper"

class AssessmentPageTest < ActionDispatch::IntegrationTest
  def user(role)
    User.find_or_create_by!(email_address: "#{role}@example.com") { |u| u.password = "password123"; u.role = role }
  end

  test "the assessment page loads for every role" do
    domain = Domain.create!(name: "Authentication")
    domain.controls.create!(description: "Every request is authenticated", default_severity: :high)
    assessment = Project.create!(name: "Demo").submit!

    %i[admin architect developer security_tester reviewer].each do |role|
      sign_in_as user(role)
      get assessment_url(assessment)
      assert_response :success, "#{role} should be able to open the assessment"
    end
  end
end
