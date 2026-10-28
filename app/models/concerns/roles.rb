module Roles
  extend ActiveSupport::Concern

  included do
    enum :role, { architect: 0, developer: 1, security_tester: 2, reviewer: 4, admin: 5 }, validate: true
  end

  def can_create_project? = admin?
  def can_submit?(project) = (project.design? && architect?) || (project.development? && developer?)
  def can_test? = security_tester?
  def can_manage_library? = admin?
  def can_manage_users? = admin?
  def can_manage_thresholds? = admin?
  def can_approve_override? = security_tester?
end
