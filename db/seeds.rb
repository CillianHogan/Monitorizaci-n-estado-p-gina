# Create admin user
user_email = 'hello@21ninjas.es'

user = User.where(email: user_email).first_or_create!(
  password: '000000000',
  password_confirmation: '000000000'
)

# Create sample domains
domain = Domain.where(url: 'https://www.21ninjas.com').first_or_create!(
  name: '21 Ninjas Website',
  user: user,
  status: :up
)

# Create sample status history for the past month
30.days.ago.to_date.upto(Date.current) do |date|
  # Create 4-6 status changes per day
  rand(4..6).times do
    recorded_at = date.to_time + rand(0..23).hours + rand(0..59).minutes
    
    # Generate more realistic status patterns
    # 70% chance of being up, 20% down, 10% error
    status = case rand(1..100)
             when 1..70 then :up
             when 71..90 then :down
             else :error
             end

    DomainStatusHistory.create!(
      domain: domain,
      status: status,
      recorded_at: recorded_at
    )
  end
end

puts "Sample domain and status history created"
