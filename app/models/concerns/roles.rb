module Roles
  extend ActiveSupport::Concern

  included do
    enum :role, { architect: 0, developer: 1, security_tester: 2, department_head: 3, reviewer: 4 }, validate: true
  end

  def can_create_project? = architect? || department_head?
  def can_submit?(project) = (project.design? && architect?) || (project.development? && developer?)
  def can_test? = security_tester?
  def can_manage_library? = security_tester? || department_head?
  def can_approve_override? = department_head?
end
