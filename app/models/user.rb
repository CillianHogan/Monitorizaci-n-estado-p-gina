# frozen_string_literal: true

class User < ApplicationRecord
  has_many :notification_channels, dependent: :destroy
  # Include default devise modules. Others available are:
  # :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable

  has_many :domains, dependent: :destroy
  has_many :api_endpoints, dependent: :destroy

  # Definición de roles de usuario
  ROLES = %w[admin manager user].freeze

  validates :role, presence: true, inclusion: { in: ROLES }

  # Métodos auxiliares para verificar roles
  def admin?
    role == 'admin'
  end

  def manager?
    role == 'manager'
  end

  def regular_user?
    role == 'user'
  end

  def pro?
    admin? || manager? || role == "pro"
  end

  def role?(requested_role)
    role == requested_role.to_s
  end

  # Límites de monitores según plan/rol
  def domain_limit
    pro? ? 50 : 3
  end

  def api_endpoint_limit
    pro? ? 50 : 3
  end

  def can_create_domain?
    domains.count < domain_limit
  end

  def can_create_api_endpoint?
    api_endpoints.count < api_endpoint_limit
  end

end
