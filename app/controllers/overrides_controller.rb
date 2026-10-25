class OverridesController < ApplicationController
  before_action :set_assessment

  def new
    require_permission! Current.user.can_approve_override?
    @override = @assessment.build_override
  end

  def create
    require_permission! Current.user.can_approve_override?
    return redirect_to(@assessment, alert: "An override is already on record.") if @assessment.override
    return redirect_to(@assessment, alert: "This assessment is already decided.") unless @assessment.editable?

    @override = @assessment.build_override(approver: Current.user,
                                           comments: params.expect(override: [ :comments ])[:comments])
    if @override.save
      redirect_to @assessment, notice: "Override recorded."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_assessment = @assessment = Assessment.find(params[:assessment_id])
end
