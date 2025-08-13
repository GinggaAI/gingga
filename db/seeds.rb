# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Create demo user if none exists
demo_user = User.find_or_create_by!(email: 'demo@example.com') do |user|
  user.password = 'password123'
  user.password_confirmation = 'password123'
end

# Create demo brand with related data
demo_brand = Brand.find_or_create_by!(user: demo_user, slug: 'demo-tech-company') do |brand|
  brand.name = 'Demo Tech Company'
  brand.industry = 'Technology'
  brand.value_proposition = 'We create innovative software solutions that help businesses scale and grow efficiently.'
  brand.mission = 'To democratize technology and make powerful tools accessible to businesses of all sizes.'
  brand.voice = 'professional'
  brand.content_language = 'en-US'
  brand.account_language = 'en-US'
  brand.subtitle_languages = [ 'en-US', 'es-ES' ]
  brand.dub_languages = [ 'en-US' ]
  brand.region = 'North America'
  brand.timezone = 'America/New_York'
  brand.guardrails = {
    banned_words: [ 'guarantee', 'instant' ],
    claims_rules: 'No unrealistic promises about results',
    tone_no_go: [ 'aggressive', 'pushy' ]
  }
  brand.resources = {
    podcast_clips: true,
    editing: true,
    ai_avatars: true,
    kling: false,
    stock: true,
    budget: true
  }
end

# Create audience for the brand
demo_brand.audiences.find_or_create_by!(name: 'Small Business Owners') do |audience|
  audience.demographic_profile = {
    age_range: '30-50',
    gender: 'mixed',
    location: 'urban/suburban',
    income_level: 'middle to upper-middle class'
  }
  audience.interests = [ 'business growth', 'technology', 'efficiency', 'productivity' ]
  audience.digital_behavior = [ 'active on LinkedIn', 'follows business content', 'engages with how-to content' ]
end

# Create product for the brand
demo_brand.products.find_or_create_by!(name: 'Business Management Suite') do |product|
  product.description = 'All-in-one software solution for managing customers, projects, and team collaboration'
  product.pricing_info = 'Starting at $49/month'
  product.url = 'https://demo-tech-company.com/products/business-suite'
end

# Create brand channels
demo_brand.brand_channels.find_or_create_by!(platform: :instagram) do |channel|
  channel.handle = '@demotechco'
  channel.priority = 1
end

demo_brand.brand_channels.find_or_create_by!(platform: :linkedin) do |channel|
  channel.handle = 'demo-tech-company'
  channel.priority = 2
end

# Create an empty strategy plan for current month
current_month = Date.current.strftime('%Y-%m')
demo_brand.creas_strategy_plans.find_or_create_by!(
  user: demo_user,
  month: current_month
) do |plan|
  plan.strategy_name = "#{Date.current.strftime('%B %Y')} Growth Strategy"
  plan.objective_of_the_month = 'awareness'
  plan.frequency_per_week = 4
  plan.monthly_themes = [ 'product showcase', 'customer success stories' ]
  plan.resources_override = {}
  plan.brand_snapshot = {
    name: demo_brand.name,
    industry: demo_brand.industry,
    voice: demo_brand.voice
  }
  plan.meta = { created_by: 'seed' }
end

puts "✅ Demo brand '#{demo_brand.name}' created with:"
puts "   - 1 audience: #{demo_brand.audiences.count}"
puts "   - 1 product: #{demo_brand.products.count}"
puts "   - #{demo_brand.brand_channels.count} channels"
puts "   - 1 strategy plan for #{current_month}"
