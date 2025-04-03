class GeneratePublicTokensForExistingDomains < ActiveRecord::Migration[8.0]
  def up
    # Obtener todos los dominios que no tienen un public_token
    domains_without_token = Domain.where(public_token: [nil, '']).to_a
    
    if domains_without_token.any?
      puts "Generando tokens públicos para #{domains_without_token.size} dominios existentes..."
      
      domains_without_token.each do |domain|
        # Usar el mismo método que el modelo utiliza para generar tokens
        token = loop do
          random_token = SecureRandom.urlsafe_base64(16)
          break random_token unless Domain.exists?(public_token: random_token)
        end
        
        # Actualizar el dominio con el nuevo token
        domain.update_column(:public_token, token)
        puts "  - Token generado para dominio: #{domain.name}"
      end
      
      puts "Tokens públicos generados exitosamente."
    else
      puts "No se encontraron dominios sin token público."
    end
  end

  def down
    # Esta migración no es reversible ya que no podemos determinar
    # qué dominios tenían tokens antes de ejecutarla
    raise ActiveRecord::IrreversibleMigration
  end
end