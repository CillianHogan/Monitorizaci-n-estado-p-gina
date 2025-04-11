# frozen_string_literal: true

module RoleAuthorization
  extend ActiveSupport::Concern

  included do
    helper_method :current_user_admin?, :current_user_manager?
  end

  # Verifica si el usuario actual tiene rol de administrador
  def current_user_admin?
    current_user&.admin?
  end

  # Verifica si el usuario actual tiene rol de manager
  def current_user_manager?
    current_user&.manager?
  end

  # Verifica si el usuario actual tiene un rol específico
  def current_user_has_role?(role)
    current_user&.role?(role)
  end

  # Requiere que el usuario tenga rol de administrador
  def require_admin
    return if current_user_admin?

    flash[:alert] = 'Acceso denegado. Se requiere rol de administrador.'
    redirect_to root_path
  end

  # Requiere que el usuario tenga rol de manager o superior
  def require_manager
    return if current_user_admin? || current_user_manager?

    flash[:alert] = 'Acceso denegado. Se requiere rol de manager o administrador.'
    redirect_to root_path
  end
end
