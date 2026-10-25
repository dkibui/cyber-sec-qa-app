# The tester's decision: forward or return. All the rules live in Assessment.
class DecisionsController < ApplicationController
  def create
    @assessment = Assessment.find(params[:assessment_id])
    require_role! :security_tester
    @assessment.update!(tester: Current.user) if @assessment.tester.nil?

    case params[:outcome]
    when "forward"
      @assessment.forward!
      notice = @assessment.project.live? ? "Forwarded. The project is live." : "Forwarded to development."
    when "return"
      @assessment.return!
      notice = "Returned to #{@assessment.returned_to.downcase}."
    else
      raise ActionController::BadRequest, "Unknown outcome"
    end
    redirect_to @assessment, notice: notice
  rescue Assessment::NotReady, Project::InvalidTransition => e
    redirect_to @assessment, alert: e.message
  end
end
