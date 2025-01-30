# Create admin user
user_email = 'hello@21ninjas.es'

unless User.exists?(email: user_email)
  User.create!(
    email: user_email,
    password: '000000000',
    password_confirmation: '000000000'
  )
  puts "Admin user created with email: #{user_email}"
else
  puts "Admin user with email #{user_email} already exists"
end
