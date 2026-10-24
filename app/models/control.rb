class Control < ApplicationRecord
  SEVERITIES = { critical: 0, high: 1, medium: 2, low: 3 }.freeze

  belongs_to :domain

  enum :default_severity, SEVERITIES, prefix: :default

  validates :description, presence: true
  validates :sequence, presence: true, uniqueness: { scope: :domain_id },
            numericality: { only_integer: true, greater_than: 0 }

  before_validation :assign_sequence, on: :create

  scope :active, -> { where(retired_at: nil) }

  # Derived for display only. Other records link by id, never by ref.
  def ref = "#{domain.number}.#{sequence}"
  def retired? = retired_at.present?
  def retire! = update!(retired_at: Time.current)
  def restore! = update!(retired_at: nil)

  private

  # Retired controls still count, so a number is never reused.
  def assign_sequence
    self.sequence ||= (Control.where(domain_id: domain_id).maximum(:sequence) || 0) + 1
  end
end
