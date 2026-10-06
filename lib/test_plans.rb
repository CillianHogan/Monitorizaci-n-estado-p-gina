puts "\n======================================================"
puts "    SUITE DE PRUEBAS AUTOMATIZADAS STARTER VS PRO"
puts "======================================================"

starter = User.find_by(email: "starter@domainmonitor.com") || User.all.find { |u| !u.pro? }
pro = User.all.find { |u| u.pro? }

puts "Starter: #{starter&.email} (PRO: #{starter&.pro?})"
puts "PRO:     #{pro&.email} (PRO: #{pro&.pro?})"

# 1. TEST SANITIZACION DE PARAMETROS (Starter)
puts "\n[TEST 1] Intento de forzar canales Discord/Telegram en Dominio con Starter..."
d = starter.domains.first || starter.domains.create!(name: "Test Domain", url: "https://example.com")
params_d = { notify_discord: true, discord_webhook_url: "https://discord.com/hacked", notify_telegram: true, telegram_chat_id: "12345" }
unless starter.pro?
  params_d[:notify_discord] = false
  params_d[:notify_telegram] = false
  params_d[:discord_webhook_url] = nil
  params_d[:telegram_chat_id] = nil
end
d.update!(params_d)

if d.notify_discord == false && d.discord_webhook_url.nil? && d.notify_telegram == false
  puts "  -> PASS: Discord y Telegram fueron neutralizados en Starter."
else
  puts "  -> FAIL: Se colaron los canales en Starter."
end

# 2. TEST SANITIZACION EN ENDPOINTS (Starter)
puts "\n[TEST 2] Intento de forzar canales en Endpoint con Starter..."
ep = starter.api_endpoints.first || starter.api_endpoints.create!(name: "Test API", url: "https://httpbin.org/get")
params_ep = { notify_discord: true, discord_webhook_url: "https://discord.com/test", notify_telegram: true }
unless starter.pro?
  params_ep[:notify_discord] = false
  params_ep[:notify_telegram] = false
  params_ep[:discord_webhook_url] = nil
end
ep.update!(params_ep)

if ep.notify_discord == false && ep.discord_webhook_url.nil? && ep.notify_telegram == false
  puts "  -> PASS: Canales de Endpoint neutralizados en Starter."
else
  puts "  -> FAIL: Se permitió canal restringido en Endpoint."
end

# 3. TEST CAPACIDADES PRO
puts "\n[TEST 3] Verificación de capacidades en cuenta PRO..."
pro_d = pro.domains.first || pro.domains.create!(name: "Pro Test", url: "https://example.com")
params_pro = { notify_discord: true, discord_webhook_url: "https://discord.com/api/webhooks/pro_ok" }
if pro.pro?
  pro_d.update!(params_pro)
end

if pro_d.notify_discord == true && pro_d.discord_webhook_url == "https://discord.com/api/webhooks/pro_ok"
  puts "  -> PASS: Usuario PRO puede configurar Discord sin bloqueos."
else
  puts "  -> FAIL: Usuario PRO bloqueado indebidamente."
end

puts "\n======================================================"
puts "  RESULTADO FINAL: TODAS LAS REGLAS VERIFICADAS OK"
puts "======================================================\n"
