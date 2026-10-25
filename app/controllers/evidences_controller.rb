class EvidencesController < ApplicationController
  before_action -> { require_role! :security_tester }
  before_action :set_finding
  before_action :ensure_editable

  def create
    @evidence = @finding.evidences.build(params.expect(evidence: [ :caption, :file ]))
    if @evidence.save
      redirect_to @finding, notice: "Evidence added."
    else
      redirect_to @finding, alert: @evidence.errors.full_messages.to_sentence
    end
  end

  def destroy
    @finding.evidences.find(params[:id]).destroy
    redirect_to @finding, notice: "Evidence removed."
  end

  private

  def set_finding = @finding = Finding.find(params[:finding_id])

  def ensure_editable
    redirect_to @finding.assessment, alert: "This assessment is already decided." unless @finding.assessment.editable?
  end
end
