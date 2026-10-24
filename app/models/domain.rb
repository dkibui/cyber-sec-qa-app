class Domain < ApplicationRecord
  has_many :controls, -> { order(:sequence) }, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true
  validates :number, presence: true, uniqueness: true,
            numericality: { only_integer: true, greater_than: 0 }

  before_validation :assign_number, on: :create

  scope :ordered, -> { order(:number) }

  private

  def assign_number
    self.number ||= (Domain.maximum(:number) || 0) + 1
  end
end
