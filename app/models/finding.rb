class Finding < ApplicationRecord
  belongs_to :assessment
  belongs_to :control_result
  has_many :evidences, dependent: :destroy

  before_validation { self.assessment ||= control_result&.assessment }
  validate :result_belongs_to_assessment

  private

  def result_belongs_to_assessment
    return if control_result.nil? || control_result.assessment_id == assessment_id
    errors.add(:control_result, "must belong to the same assessment")
  end
end
