class Project < ApplicationRecord
  belongs_to :architect, class_name: "User", optional: true
  belongs_to :developer, class_name: "User", optional: true

  # design -> design_review -> development -> security_testing -> live
  enum :stage, { design: 0, design_review: 1, development: 2, security_testing: 3, live: 4 }, validate: true

  validates :name, presence: true
end