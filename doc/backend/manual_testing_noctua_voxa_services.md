# Manual Testing Guide: Noctua and Voxa Services

This guide provides step-by-step instructions for manually testing the Noctua (strategy generation) and Voxa (content refinement) services through the Rails console after the batch processing refactor.

## Overview

Both services now use **batch processing** to ensure reliable operation:
- **Maximum 7 content items per batch**
- **4 weekly batches** for monthly strategy generation
- **Sequential processing** with context sharing to avoid duplications
- **Background job processing** with solid_queue

## Prerequisites

1. Start the Rails console: `rails console`
2. Ensure you have test data:
   - A User with API tokens configured
   - A Brand with audiences, products, and channels
   - Valid OpenAI API credentials

## Testing Noctua Strategy Service (Batch Processing)

### 1. Setup Test Data

```ruby
# Create or find test user and brand
user = User.first || create(:user)
brand = user.brands.first || create(:brand, user: user)

# Ensure brand has required associations
brand.audiences.create!(
  demographic_profile: "Tech professionals, 25-45 years old",
  interests: "Technology, innovation, productivity tools",
  digital_behavior: "Active on LinkedIn and Twitter"
) if brand.audiences.empty?

brand.products.create!(
  name: "AI Assistant",
  description: "An intelligent productivity tool"
) if brand.products.empty?

brand.brand_channels.create!(
  platform: "instagram",
  handle: "@testbrand",
  priority: 1
) if brand.brand_channels.empty?
```

### 2. Prepare Strategy Brief

```ruby
brief = {
  brand_name: brand.name,
  brand_slug: brand.slug,
  industry: brand.industry,
  objective_of_the_month: "Increase brand awareness and engagement",
  frequency_per_week: 4,
  monthly_themes: "Innovation, Technology, Productivity"
}

month = "2025-09"  # Use future month to avoid conflicts

strategy_form = {
  objective_of_the_month: "Increase brand awareness",
  frequency_per_week: 4,
  monthly_themes: "innovation,technology,productivity"
}
```

### 3. Test Noctua Service (Async - Recommended)

```ruby
# Initialize the service with batch processing
service = Creas::NoctuaStrategyService.new(
  user: user,
  brief: brief,
  brand: brand,
  month: month,
  strategy_form: strategy_form
)

# Call the service (returns immediately with pending status)
strategy_plan = service.call

puts "Strategy Plan ID: #{strategy_plan.id}"
puts "Status: #{strategy_plan.status}"
puts "Created at: #{strategy_plan.created_at}"

# Monitor progress
strategy_plan.reload
puts "Current status: #{strategy_plan.status}"
puts "Error message: #{strategy_plan.error_message}" if strategy_plan.error_message

# Check batch processing metadata
puts "Meta data: #{strategy_plan.meta}"

# Wait for completion (check every 5 seconds)
while strategy_plan.reload.status == "pending" || strategy_plan.status == "processing"
  puts "Status: #{strategy_plan.status} - #{Time.current}"
  sleep 5
end

puts "Final status: #{strategy_plan.status}"
```

### 4. Verify Noctua Results

```ruby
strategy_plan.reload

# Check final status and data
puts "=== STRATEGY PLAN RESULTS ==="
puts "Status: #{strategy_plan.status}"
puts "Strategy Name: #{strategy_plan.strategy_name}"
puts "Objective: #{strategy_plan.objective_of_the_month}"
puts "Frequency per week: #{strategy_plan.frequency_per_week}"
puts "Monthly Themes: #{strategy_plan.monthly_themes}"

# Check weekly plan structure
puts "\n=== WEEKLY PLAN ==="
strategy_plan.weekly_plan.each_with_index do |week, index|
  puts "Week #{index + 1}:"
  puts "  Week number: #{week['week']}"
  puts "  Ideas count: #{week['ideas']&.count || 0}"
  puts "  Publish cadence: #{week['publish_cadence']}"
  
  if week['ideas']&.any?
    puts "  Sample idea: #{week['ideas'].first['title']}" if week['ideas'].first['title']
  end
end

# Check batch processing metadata
puts "\n=== BATCH PROCESSING INFO ==="
puts "Noctua batches: #{strategy_plan.meta&.dig('noctua_batches')&.keys&.count || 0}"
puts "Strategy info from AI: #{strategy_plan.meta&.dig('strategy_info_from_ai').present?}"
puts "Full weekly plan from AI: #{strategy_plan.meta&.dig('full_weekly_plan_from_ai').present?}"

# Check AI responses
ai_responses = AiResponse.where(
  user: user,
  service_name: "noctua"
).where("created_at > ?", 1.hour.ago).order(:created_at)

puts "\n=== AI RESPONSES ==="
puts "Total AI calls: #{ai_responses.count}"
ai_responses.each do |response|
  puts "Batch #{response.batch_number}/#{response.total_batches}: #{response.raw_response&.length || 0} characters"
end
```

## Testing Voxa Content Service (Batch Processing)

### 1. Create Content Items for Refinement

```ruby
# Ensure we have a completed strategy with content items
unless strategy_plan.creas_content_items.any?
  # Initialize content items from the weekly plan
  initializer = Creas::ContentItemInitializerService.new(strategy_plan: strategy_plan)
  content_items = initializer.call
  puts "Created #{content_items.count} content items"
end

# Verify content items exist
puts "Content items count: #{strategy_plan.creas_content_items.count}"
puts "Sample content item: #{strategy_plan.creas_content_items.first&.content_name}"
```

### 2. Test Voxa Service (Async - Recommended)

```ruby
# Initialize Voxa service
voxa_service = Creas::VoxaContentService.new(strategy_plan: strategy_plan)

# Call the service (returns immediately, processes in background)
result = voxa_service.call

puts "Voxa processing initiated"
puts "Strategy plan ID: #{strategy_plan.id}"
puts "Content items to refine: #{strategy_plan.creas_content_items.count}"

# Monitor content item status updates
puts "\n=== MONITORING VOXA PROCESSING ==="
initial_statuses = strategy_plan.creas_content_items.pluck(:status).tally
puts "Initial statuses: #{initial_statuses}"

# Check progress every 10 seconds
5.times do |i|
  sleep 10
  strategy_plan.reload
  current_statuses = strategy_plan.creas_content_items.pluck(:status).tally
  puts "After #{(i + 1) * 10}s - Statuses: #{current_statuses}"
  
  # Check if any items are still being processed
  if strategy_plan.creas_content_items.where(status: 'draft').empty?
    puts "All content items processed!"
    break
  end
end
```

### 3. Verify Voxa Results

```ruby
strategy_plan.reload

puts "\n=== VOXA REFINEMENT RESULTS ==="

# Check final status distribution
final_statuses = strategy_plan.creas_content_items.pluck(:status).tally
puts "Final statuses: #{final_statuses}"

# Sample refined content
refined_items = strategy_plan.creas_content_items.where(status: 'in_production')
puts "Refined items: #{refined_items.count}"

refined_items.limit(3).each_with_index do |item, index|
  puts "\n--- Refined Item #{index + 1} ---"
  puts "Content ID: #{item.content_id}"
  puts "Title: #{item.content_name}"
  puts "Status: #{item.status}"
  puts "Platform: #{item.platform}"
  puts "Content Type: #{item.content_type}"
  puts "Hook: #{item.hook&.truncate(100)}"
  puts "Description: #{item.post_description&.truncate(100)}"
  puts "Batch: #{item.batch_number}/#{item.batch_total}" if item.batch_number
end

# Check Voxa AI responses
voxa_responses = AiResponse.where(
  user: user,
  service_name: "voxa"
).where("created_at > ?", 1.hour.ago).order(:created_at)

puts "\n=== VOXA AI RESPONSES ==="
puts "Total Voxa AI calls: #{voxa_responses.count}"
voxa_responses.each do |response|
  puts "Batch #{response.batch_number}/#{response.total_batches}: #{response.raw_response&.length || 0} characters"
  
  # Check for any errors
  if response.raw_response&.include?("error")
    puts "  ERROR detected in response"
  end
end
```

## Testing Error Scenarios

### 1. Test with Invalid API Keys

```ruby
# Temporarily break OpenAI configuration
original_key = ENV['OPENAI_API_KEY']
ENV['OPENAI_API_KEY'] = 'invalid-key'

# Test Noctua with invalid key
begin
  service = Creas::NoctuaStrategyService.new(
    user: user,
    brief: brief,
    brand: brand,
    month: "2025-10",
    strategy_form: strategy_form
  )
  
  failed_plan = service.call
  
  # Wait a bit for background processing
  sleep 10
  failed_plan.reload
  
  puts "Failed plan status: #{failed_plan.status}"
  puts "Error message: #{failed_plan.error_message}"
  
rescue => e
  puts "Exception caught: #{e.message}"
ensure
  # Restore original key
  ENV['OPENAI_API_KEY'] = original_key
end
```

### 2. Test with Incomplete Brand Data

```ruby
# Create brand with minimal data
minimal_brand = Brand.create!(
  user: user,
  name: "Minimal Test Brand",
  slug: "minimal-test-brand",
  industry: "test"
)

minimal_brief = {
  brand_name: minimal_brand.name,
  brand_slug: minimal_brand.slug,
  industry: minimal_brand.industry,
  objective_of_the_month: "Test with minimal data",
  frequency_per_week: 2
}

service = Creas::NoctuaStrategyService.new(
  user: user,
  brief: minimal_brief,
  brand: minimal_brand,
  month: "2025-11"
)

minimal_plan = service.call

# Monitor for incomplete brief handling
sleep 10
minimal_plan.reload

puts "Minimal plan status: #{minimal_plan.status}"
puts "Error message: #{minimal_plan.error_message}"
```

## Performance Testing

### 1. Monitor Batch Processing Performance

```ruby
# Test with maximum content (20+ items)
large_brief = brief.merge(frequency_per_week: 5)

start_time = Time.current
large_service = Creas::NoctuaStrategyService.new(
  user: user,
  brief: large_brief,
  brand: brand,
  month: "2025-12",
  strategy_form: strategy_form.merge(frequency_per_week: 5)
)

large_plan = large_service.call
puts "Service call completed in: #{Time.current - start_time} seconds"

# Monitor batch processing time
batch_start = Time.current
while large_plan.reload.status.in?(['pending', 'processing'])
  puts "Still processing... #{Time.current - batch_start} seconds elapsed"
  sleep 10
  
  # Timeout after 5 minutes
  if Time.current - batch_start > 5.minutes
    puts "TIMEOUT: Processing took longer than 5 minutes"
    break
  end
end

total_time = Time.current - batch_start
puts "Total processing time: #{total_time} seconds"
puts "Final status: #{large_plan.status}"

# Analyze batch processing efficiency
if large_plan.meta&.dig('noctua_batches')
  batches = large_plan.meta['noctua_batches']
  batches.each do |batch_num, batch_data|
    puts "Batch #{batch_num}: #{batch_data['total_ideas']} ideas, processed at #{batch_data['processed_at']}"
  end
end
```

## Troubleshooting Common Issues

### 1. Class Reloading Issues (Development Mode)

If you encounter errors like:
```
User(#298864) expected, got #<User...> which is an instance of User(#272304) (ActiveRecord::AssociationTypeMismatch)
```

This is a Rails development mode class reloading issue. **Solutions:**

**Option 1: Reload Objects (Quick Fix)**
```ruby
# Reload your objects to get fresh instances
user = User.find(user.id)
brand = Brand.find(brand.id)

# Or reload existing objects
user.reload
brand.reload
```

**Option 2: Restart Console (Recommended)**
```bash
exit  # Exit current console
rails console  # Start fresh
```

**Option 3: Use Fresh Database Queries**
```ruby
# Always fetch fresh from database instead of using cached objects
user_id = "your-user-id-here"
user = User.find(user_id)
brand = user.brands.first

# Proceed with testing
service = Creas::NoctuaStrategyService.new(user: user, brief: brief, brand: brand, month: month)
```

### 2. Check Background Job Status

```ruby
# Check if jobs are running
require 'solid_queue'

# Check job status
jobs = SolidQueue::Job.where("created_at > ?", 1.hour.ago)
puts "Recent jobs: #{jobs.count}"

failed_jobs = jobs.where.not(finished_at: nil, failed_at: nil)
puts "Failed jobs: #{failed_jobs.count}"

failed_jobs.each do |job|
  puts "Failed job: #{job.class_name} - #{job.exception_executions.last&.exception_message}"
end
```

### 2. Check Service Dependencies

```ruby
# Verify OpenAI client
begin
  client = GinggaOpenAI::ChatClient.new(user: user)
  test_response = client.chat!(
    system: "You are a helpful assistant.",
    user: "Say 'test successful' if you can read this."
  )
  puts "OpenAI test: #{test_response}"
rescue => e
  puts "OpenAI error: #{e.message}"
end

# Check brand data completeness
puts "\n=== BRAND DATA COMPLETENESS ==="
puts "Brand: #{brand.name}"
puts "Audiences: #{brand.audiences.count}"
puts "Products: #{brand.products.count}"
puts "Channels: #{brand.brand_channels.count}"
puts "Industry: #{brand.industry}"
puts "Resources: #{brand.resources}"
```

### 3. Clean Up Test Data

```ruby
# Clean up test strategy plans
test_plans = CreasStrategyPlan.where(user: user)
  .where("month LIKE ?", "2025-%")
  .where("created_at > ?", 1.day.ago)

puts "Cleaning up #{test_plans.count} test strategy plans"
test_plans.destroy_all

# Clean up test AI responses
test_responses = AiResponse.where(user: user)
  .where("created_at > ?", 1.day.ago)
  
puts "Cleaning up #{test_responses.count} test AI responses"
test_responses.destroy_all

puts "Cleanup completed"
```

## Expected Behavior After Batch Processing Refactor

### Noctua Service
- ✅ Creates strategy plan immediately with `pending` status
- ✅ Processes in 4 weekly batches (max 7 items each)
- ✅ Sequential batch processing with context sharing
- ✅ Final status: `completed` with assembled `weekly_plan`
- ✅ Preserves strategy-level information (name, objective, themes)
- ✅ Error handling with `failed` status and error messages

### Voxa Service
- ✅ Processes existing content items in batches (max 7 items each)
- ✅ Updates existing items instead of creating duplicates
- ✅ Status progression: `draft` → `in_production`
- ✅ Preserves original `content_id` for matching
- ✅ Creates new items only when no match found
- ✅ Batch processing with retry mechanisms

This manual testing approach ensures both services work correctly with the new batch processing system while maintaining reliability and avoiding the issues that prompted the refactor.