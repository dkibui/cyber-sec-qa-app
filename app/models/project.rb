class Project < ApplicationRecord
  class InvalidTransition < StandardError; end

  # design -> design_review -> development -> security_testing -> live
  SUBMIT = { "design" => [ "design_review", :design ], "development" => [ "security_testing", :testing ] }.freeze

  belongs_to :architect, class_name: "User", optional: true
  belongs_to :developer, class_name: "User", optional: true
  has_many :assessments, dependent: :destroy

  enum :stage, { design: 0, design_review: 1, development: 2, security_testing: 3, live: 4 }, validate: true

  validates :name, presence: true

  def current_assessment = assessments.outcome_in_progress.order(:created_at).last

  # The architect submits the design, or the developers submit the build. Starts the next security check.
  def submit!
    target, gate = SUBMIT.fetch(stage) do
      raise InvalidTransition, "A project in #{stage.humanize} cannot be submitted for a security check."
    end
    transaction do
      previous = assessments.order(:created_at).last
      update!(stage: target)
      assessments.create!(
        gate: gate,
        round: assessments.where(gate: gate).count + 1,
        components_in_scope: previous&.components_in_scope
      )
    end
  end
end
