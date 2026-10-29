class AssessmentsController < ApplicationController
  def show
    @assessment = Assessment.find(params[:id])
    @missing = @assessment.missing_evidence
    @open_criticals = @assessment.open_critical_count
    @results = @assessment.control_results.includes(findings: :evidences, control: :domain)
                          .sort_by { |r| [ r.control.domain.number, r.control.sequence ] }
                          .group_by { |r| r.control.domain }
  end
end
