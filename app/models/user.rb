# frozen_string_literal: true

class User < ApplicationRecord
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

  def role?(requested_role)
    role == requested_role.to_s
  end
end
