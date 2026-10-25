class ControlResult < ApplicationRecord
  belongs_to :assessment
  belongs_to :control

  enum :status, { pending: 0, passed: 1, failed: 2, partial: 3, not_applicable: 4 }, prefix: true, validate: true
  enum :severity, Control::SEVERITIES, prefix: true, validate: true

  validates :control_id, uniqueness: { scope: :assessment_id }

  scope :requiring_evidence, -> { where(status: [ :failed, :partial ]) }

  # Failed and Partial are vulnerabilities and will need an evidence pack (step 07).
  def requires_evidence? = status_failed? || status_partial?
end
