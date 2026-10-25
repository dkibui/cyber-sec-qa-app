class Assessment < ApplicationRecord
  belongs_to :project
  belongs_to :tester, class_name: "User", optional: true
  has_many :control_results, dependent: :destroy

  enum :gate, { design: 0, testing: 1 }, prefix: true
  enum :outcome, { in_progress: 0, forwarded: 1, returned: 2 }, prefix: true

  validates :round, numericality: { only_integer: true, greater_than: 0 },
            uniqueness: { scope: [ :project_id, :gate ] }

  after_create :build_results

  def editable? = outcome_in_progress?
  def returned_to = gate_design? ? "Solutions architect" : "Developers"

  def pending_count = control_results.status_pending.count

  private

  # Every active control in the library becomes a Pending result.
  def build_results
    Control.active.find_each do |control|
      control_results.create!(control: control, severity: control.default_severity)
    end
  end
end