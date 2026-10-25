class ControlResultsController < ApplicationController
  def update
    require_role! :security_tester
    result = ControlResult.find(params[:id])
    assessment = result.assessment
    return redirect_to(assessment, alert: "This assessment is already decided.") unless assessment.editable?

    assessment.update!(tester: Current.user) if assessment.tester.nil?
    if result.update(params.expect(control_result: [ :status, :severity, :comments, :owner ]))
      redirect_to assessment_path(assessment, anchor: helpers.dom_id(result)), notice: "#{result.control.ref} saved."
    else
      redirect_to assessment, alert: result.errors.full_messages.to_sentence
    end
  end
end
