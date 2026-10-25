class AssessmentsController < ApplicationController
  def show
    @assessment = Assessment.find(params[:id])
    @results = @assessment.control_results.includes(control: :domain)
                          .sort_by { |r| [ r.control.domain.number, r.control.sequence ] }
                          .group_by { |r| r.control.domain }
  end
end
