class FindingsController < ApplicationController
  before_action -> { require_role! :security_tester }, only: %i[new create edit update destroy]
  before_action :set_assessment, only: %i[new create]
  before_action :set_finding, only: %i[show edit update destroy]
  before_action :ensure_editable, only: %i[new create edit update destroy]

  def show
    @evidences = @finding.evidences.with_attached_file.order(:created_at)
  end

  def new
    @finding = @assessment.findings.build(control_result_id: params[:control_result_id])
  end

  def create
    @finding = @assessment.findings.build(finding_params)
    if @finding.save
      redirect_to @finding, notice: "Finding saved. Now add evidence."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @finding.update(finding_params.except(:control_result_id))
      redirect_to @finding, notice: "Finding updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @finding.destroy
    redirect_to @assessment, notice: "Finding removed."
  end

  private

  def set_assessment = @assessment = Assessment.find(params[:assessment_id])

  def set_finding
    @finding = Finding.find(params[:id])
    @assessment = @finding.assessment
  end

  def ensure_editable
    redirect_to @assessment, alert: "This assessment is already decided." unless @assessment.editable?
  end

  def finding_params
    params.expect(finding: [ :control_result_id, :category, :test_objective, :observations ])
  end
end
