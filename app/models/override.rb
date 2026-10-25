# A department head's recorded exception allowing a forward with open Critical failures.
class Override < ApplicationRecord
  belongs_to :assessment
  belongs_to :approver, class_name: "User"

  validates :comments, presence: true
  validate { errors.add(:approver, "must be a department head") unless approver&.department_head? }
end
