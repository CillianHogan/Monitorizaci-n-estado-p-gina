# frozen_string_literal: true

class SetExistingUsersAsAdmin < ActiveRecord::Migration[8.0]
  def up
    # Actualizar todos los usuarios existentes para asignarles el rol de administrador
    User.where.not(role: 'admin').update_all(role: 'admin')
    puts "Se ha actualizado el rol de #{User.count} usuarios a 'admin'"
  end

  def down
    # Revertir todos los usuarios a rol 'user' (valor por defecto)
    # Nota: Esta operación no puede determinar cuáles eran los roles originales
    User.where(role: 'admin').update_all(role: 'user')
    puts "Se ha revertido el rol de todos los usuarios administradores a 'user'"
  end
end
