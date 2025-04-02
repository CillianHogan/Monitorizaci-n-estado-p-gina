# frozen_string_literal: true

class ConfirmExistingUsers < ActiveRecord::Migration[8.0]
  def up
    # Confirmar todos los usuarios existentes que no tienen confirmed_at establecido
    User.where(confirmed_at: nil).update_all(confirmed_at: Time.current)
  end

  def down
    # No se puede revertir esta migración de manera segura
    # ya que no podemos determinar qué usuarios estaban confirmados originalmente
  end
end