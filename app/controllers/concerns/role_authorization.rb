module RoleAuthorization
  extend ActiveSupport::Concern

  class NotAuthorized < StandardError; end

  included do
    rescue_from NotAuthorized do
      redirect_back_or_to root_path, alert: "You are not allowed to do that."
    end
  end

  private

  def require_role!(*roles)
    raise NotAuthorized unless roles.include?(Current.user&.role&.to_sym)
  end

  def require_permission!(allowed)
    raise NotAuthorized unless allowed
  end
end
