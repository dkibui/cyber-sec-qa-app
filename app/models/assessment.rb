class Assessment < ApplicationRecord
  class NotReady < StandardError; end

  belongs_to :project
  belongs_to :tester, class_name: "User", optional: true
  has_many :control_results, dependent: :destroy
  has_many :findings, dependent: :destroy
  has_one :override, dependent: :destroy

  enum :gate, { design: 0, testing: 1 }, prefix: true
  enum :outcome, { in_progress: 0, forwarded: 1, returned: 2 }, prefix: true

  validates :round, numericality: { only_integer: true, greater_than: 0 },
            uniqueness: { scope: [ :project_id, :gate ] }

  after_create :build_results

  def editable? = outcome_in_progress?
  def returned_to = gate_design? ? "Solutions architect" : "Developers"

  def pending_count = control_results.status_pending.count
  def open_critical_count = control_results.requiring_evidence.severity_critical.count

  def missing_evidence
    control_results.requiring_evidence.includes(findings: :evidences).reject(&:evidence_complete?)
  end

  def ready_for_decision? = pending_count.zero? && missing_evidence.empty?

  # Rule: an open Critical vulnerability needs a department head override with comments.
  def override_on_record? = override.present? && override.comments.present?

  def forward!
    raise NotReady, "This assessment has already been decided." unless editable?
    raise NotReady, "#{pending_count} control(s) are still Pending." if pending_count.positive?

    missing = missing_evidence
    raise NotReady, "Evidence is missing for: #{missing.map { |r| r.control.ref }.join(', ')}." if missing.any?

    if open_critical_count.positive? && !override_on_record?
      raise NotReady, "Open Critical failures need a recorded override with comments."
    end

    transaction do
      update!(outcome: :forwarded, decided_at: Time.current)
      project.advance!
    end
  end

  def return!
    raise NotReady, "This assessment has already been decided." unless editable?
    raise NotReady, "Nothing has failed, so there is nothing to return." unless control_results.requiring_evidence.exists?

    transaction do
      update!(outcome: :returned, decided_at: Time.current)
      project.send_back!
    end
  end

  private

  def build_results
    Control.active.find_each do |control|
      control_results.create!(control: control, severity: control.default_severity)
    end
  end
end
