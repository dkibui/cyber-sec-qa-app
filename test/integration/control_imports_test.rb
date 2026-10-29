require "test_helper"

class ControlImportsTest < ActionDispatch::IntegrationTest
  CSV_TEXT = <<~CSV
    ID,Control / Test Description,OWASP / Ref,CWE / NIST,Status,Severity,Comments / Findings,Owner
    1.0 AUTHENTICATION,,,,,,,
    1.1,Every request is authenticated,API2:2023,CWE-306,Failed,High,Core APIs,Owner
  CSV

  def user(role)
    User.find_or_create_by!(email_address: "#{role}@example.com") { |u| u.password = "password123"; u.role = role }
  end

  def upload(text)
    Rack::Test::UploadedFile.new(StringIO.new(text), "text/csv", original_filename: "controls.csv")
  end

  test "the preview saves nothing" do
    sign_in_as user(:admin)
    post preview_control_import_url, params: { file: upload(CSV_TEXT) }
    assert_response :success
    assert_match "Authentication", response.body
    assert_equal 0, Control.count
    assert_equal 0, Domain.count
  end

  test "confirming saves the controls" do
    sign_in_as user(:admin)
    post confirm_control_import_url, params: { csv: CSV_TEXT }
    assert_redirected_to domains_url
    assert_equal 1, Control.count
  end

  test "other roles cannot import" do
    %i[architect developer security_tester reviewer].each do |role|
      sign_in_as user(role)
      post confirm_control_import_url, params: { csv: CSV_TEXT }
      assert_equal 0, Control.count, "#{role} should not be able to import"
    end
  end
end
