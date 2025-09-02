# Batch Processing Feature Testing Guide

## Overview

This document provides comprehensive testing procedures for the new batch processing features implemented in the Voxa Content Service and Noctua Strategy Service. These features ensure reliable content generation through intelligent batching and retry mechanisms.

---

## 🚀 **New Features to Test**

### 1. **Batch Processing Jobs**
- `GenerateVoxaContentBatchJob` - Processes Voxa content generation in batches
- `GenerateNoctuaStrategyBatchJob` - Processes Noctua strategy generation in batches
- Enhanced job retry mechanisms with exponential backoff

### 2. **Content Quantity Guarantee**
- Automatic verification of expected vs actual content count
- Intelligent retry mechanism for missing content items
- Enhanced uniqueness generation to avoid validation conflicts

### 3. **Enhanced Status Tracking**
- Strategy plan status updates (`pending` → `processing` → `completed`/`failed`)
- Batch tracking with `batch_id`, `batch_number`, and `total_batches`
- Comprehensive logging and error reporting

---

## 🧪 **Automated Testing Procedures**

### **1. Full Test Suite Execution**
```bash
# Run complete test suite
bundle exec rspec

# Run specific batch processing tests
bundle exec rspec spec/jobs/generate_voxa_content_batch_job_spec.rb
bundle exec rspec spec/jobs/generate_noctua_strategy_batch_job_spec.rb
```

### **2. Integration Tests**
```bash
# Test content quantity guarantee
bundle exec rspec spec/integration/content_quantity_guarantee_integration_spec.rb

# Test content uniqueness and no duplication
bundle exec rspec spec/integration/voxa_no_duplication_spec.rb

# Test day of week content placement
bundle exec rspec spec/integration/day_of_week_content_placement_spec.rb

# Test frequency per week validation
bundle exec rspec spec/integration/frequency_per_week_spec.rb
```

### **3. Service Layer Tests**
```bash
# Test enhanced services
bundle exec rspec spec/services/creas/content_item_initializer_service_spec.rb
bundle exec rspec spec/services/creas/voxa_content_service_spec.rb
bundle exec rspec spec/services/creas/noctua_strategy_service_spec.rb
```

### **4. VCR Cassette Tests**
```bash
# Test with recorded API responses
bundle exec rspec spec/services/creas/voxa_content_service_spec.rb
bundle exec rspec spec/services/creas/noctua_strategy_service_spec.rb

# Available cassettes:
# - spec/cassettes/noctua_strategy_success.yml
# - spec/cassettes/noctua_strategy_invalid_json.yml
# - spec/cassettes/noctua_incomplete_brief_error.yml
```

---

## 🔧 **Manual Testing Procedures**

### **1. Basic Batch Processing Test**

#### **Setup:**
```ruby
# In Rails console
user = User.first
brand = user.brands.first

# Create a strategy plan with multiple weeks
strategy_plan = CreasStrategyPlan.create!(
  user: user,
  brand: brand,
  status: :pending,
  weekly_plan: [
    {
      "week_number" => 1,
      "ideas" => [
        {"title" => "Content 1", "type" => "post"},
        {"title" => "Content 2", "type" => "post"},
        {"title" => "Content 3", "type" => "post"}
      ]
    },
    {
      "week_number" => 2,
      "ideas" => [
        {"title" => "Content 4", "type" => "post"},
        {"title" => "Content 5", "type" => "post"}
      ]
    }
  ]
)
```

#### **Execute Batch Job:**
```ruby
# Trigger batch processing
GenerateVoxaContentBatchJob.perform_later(
  strategy_plan.id,
  1,  # batch_number
  2,  # total_batches  
  SecureRandom.uuid  # batch_id
)
```

#### **Verify Results:**
```ruby
# Check status updates
strategy_plan.reload
puts "Strategy Plan Status: #{strategy_plan.status}"

# Check content items created
content_items = strategy_plan.creas_content_items
puts "Content Items Created: #{content_items.count}"
puts "Expected Content Items: 5"

# Verify all content has batch information
content_items.each do |item|
  puts "Item: #{item.content_title}, Batch ID: #{item.batch_id}"
end
```

### **2. Content Quantity Guarantee Test**

#### **Simulate Missing Content Scenario:**
```ruby
# In Rails console - simulate a scenario where some content fails to create
strategy_plan = CreasStrategyPlan.create!(
  user: User.first,
  brand: User.first.brands.first,
  status: :pending,
  weekly_plan: [
    {
      "week_number" => 1,
      "ideas" => Array.new(10) { |i| {"title" => "Content #{i+1}", "type" => "post"} }
    }
  ]
)

# Run ContentItemInitializerService directly
service = Creas::ContentItemInitializerService.new(strategy_plan: strategy_plan)
created_items = service.call

puts "Expected: 10 items"
puts "Created: #{created_items.count} items"
puts "Guarantee working: #{created_items.count >= 10 ? 'YES' : 'NO'}"
```

### **3. Error Handling and Retry Test**

#### **Test Job Retry Mechanism:**
```ruby
# Force a job failure to test retry logic
class TestFailureJob < ApplicationJob
  retry_on StandardError, wait: :exponentially_longer, attempts: 3
  
  def perform(strategy_plan_id)
    # Simulate failure on first 2 attempts
    @attempt_count = (@attempt_count || 0) + 1
    if @attempt_count <= 2
      raise StandardError, "Simulated failure attempt #{@attempt_count}"
    end
    
    puts "Job succeeded on attempt #{@attempt_count}"
  end
end

# Execute and monitor
TestFailureJob.perform_later(strategy_plan.id)
```

### **4. Status Tracking Test**

#### **Monitor Status Transitions:**
```ruby
strategy_plan = CreasStrategyPlan.create!(
  user: User.first,
  brand: User.first.brands.first,
  status: :pending,
  weekly_plan: [{"week_number" => 1, "ideas" => [{"title" => "Test", "type" => "post"}]}]
)

puts "Initial Status: #{strategy_plan.status}"

# Trigger processing
GenerateVoxaContentBatchJob.perform_later(strategy_plan.id, 1, 1, SecureRandom.uuid)

# Check status updates (wait a moment for processing)
sleep(2)
strategy_plan.reload
puts "Processing Status: #{strategy_plan.status}"
```

---

## 🌐 **Internationalization (i18n) Testing**

### **1. Language Switcher Component Test**
```bash
# Test language switcher component
bundle exec rspec spec/components/ui/language_switcher_component_spec.rb

# Should achieve 96%+ coverage
```

### **2. Manual i18n Testing**
```ruby
# In Rails console
I18n.locale = :en
puts I18n.t("nav.english")  # Should return "English"

I18n.locale = :es  
puts I18n.t("nav.spanish")  # Should return "Español"

# Test locale switching paths
component = Ui::LanguageSwitcherComponent.new(current_locale: :en)
puts component.send(:switch_locale_path, 'es')  # Should return "/es/"
```

### **3. Browser Testing for Language Switching**
1. Navigate to any page (e.g., `/plannings`)
2. Use the language switcher in the UI
3. Verify URL changes correctly (e.g., `/plannings` → `/es/plannings`)
4. Verify content language changes
5. Verify switching back maintains URL structure

---

## 📊 **Performance Testing**

### **1. Batch Processing Performance**
```ruby
# Test large content generation
large_strategy_plan = CreasStrategyPlan.create!(
  user: User.first,
  brand: User.first.brands.first,
  status: :pending,
  weekly_plan: Array.new(4) do |week_index|
    {
      "week_number" => week_index + 1,
      "ideas" => Array.new(20) { |i| {"title" => "Content W#{week_index+1}_#{i+1}", "type" => "post"} }
    }
  end
)

# Measure performance
start_time = Time.current
GenerateVoxaContentBatchJob.perform_now(large_strategy_plan.id, 1, 4, SecureRandom.uuid)
end_time = Time.current

puts "Processing Time: #{end_time - start_time} seconds"
puts "Items Created: #{large_strategy_plan.reload.creas_content_items.count}"
```

### **2. Memory Usage Monitoring**
```ruby
# Monitor memory usage during batch processing
require 'objspace'

before_memory = ObjectSpace.memsize_of_all
service = Creas::ContentItemInitializerService.new(strategy_plan: strategy_plan)
service.call
after_memory = ObjectSpace.memsize_of_all

puts "Memory Delta: #{(after_memory - before_memory) / 1024 / 1024} MB"
```

---

## 🚨 **Error Scenarios Testing**

### **1. API Failure Handling**
```ruby
# Test API failure recovery
# Mock OpenAI service failure
allow(GinggaOpenai::ChatClient).to receive(:new).and_raise(StandardError, "API unavailable")

# Execute service and verify graceful handling
service = Creas::VoxaContentService.new(strategy_plan: strategy_plan, week_number: 1)
result = service.call

puts "Service handled error gracefully: #{result.success? ? 'NO - should fail' : 'YES'}"
puts "Error message: #{result.error}"
```

### **2. Database Constraint Violations**
```ruby
# Test uniqueness constraint handling
strategy_plan = CreasStrategyPlan.create!(
  user: User.first,
  brand: User.first.brands.first,
  status: :pending,
  weekly_plan: [{"week_number" => 1, "ideas" => [{"title" => "Duplicate Test", "type" => "post"}]}]
)

# Create initial content
service = Creas::ContentItemInitializerService.new(strategy_plan: strategy_plan)
first_run = service.call

# Try to create duplicate content (should be handled gracefully)
second_run = service.call

puts "First run items: #{first_run.count}"
puts "Second run items: #{second_run.count}"
puts "Total unique items: #{strategy_plan.creas_content_items.count}"
```

---

## 📝 **Test Coverage Verification**

### **1. Generate Coverage Report**
```bash
# Run tests with coverage
bundle exec rspec

# View coverage report
open coverage/index.html

# Verify key components have 90%+ coverage:
# - app/jobs/generate_voxa_content_batch_job.rb
# - app/jobs/generate_noctua_strategy_batch_job.rb  
# - app/services/creas/content_item_initializer_service.rb
# - app/components/ui/language_switcher_component.rb (96%+)
```

### **2. Critical Path Coverage**
Ensure these critical paths are covered:
- ✅ Batch job execution and error handling
- ✅ Content quantity verification and retry logic
- ✅ Status tracking and transitions
- ✅ API failure recovery mechanisms
- ✅ Database transaction safety
- ✅ Internationalization functionality

---

## 🔍 **Debugging and Monitoring**

### **1. Log Monitoring**
```bash
# Monitor application logs during testing
tail -f log/development.log | grep -E "(Voxa|Noctua|Batch|ContentItem)"
```

### **2. Job Queue Monitoring**
```ruby
# In Rails console - monitor job queue
puts "Pending Jobs: #{Sidekiq::Queue.new.size}"
puts "Failed Jobs: #{Sidekiq::RetrySet.new.size}"
puts "Dead Jobs: #{Sidekiq::DeadSet.new.size}"
```

### **3. Database State Verification**
```sql
-- Check batch processing data
SELECT COUNT(*) as total_items, batch_id, batch_number 
FROM creas_content_items 
WHERE batch_id IS NOT NULL 
GROUP BY batch_id, batch_number;

-- Check strategy plan status distribution  
SELECT status, COUNT(*) 
FROM creas_strategy_plans 
GROUP BY status;
```

---

## ✅ **Test Checklist**

### **Automated Tests**
- [ ] All RSpec tests pass (`bundle exec rspec`)
- [ ] Integration tests pass
- [ ] VCR cassette tests pass
- [ ] Component tests achieve 90%+ coverage

### **Manual Tests**
- [ ] Batch processing creates expected content items
- [ ] Content quantity guarantee works under failure conditions
- [ ] Status tracking updates correctly
- [ ] Error handling works gracefully
- [ ] Language switching functions properly
- [ ] Performance is acceptable for large content sets

### **Edge Cases**
- [ ] API failures are handled gracefully
- [ ] Database constraints don't break processing
- [ ] Memory usage remains reasonable
- [ ] Concurrent job execution works correctly
- [ ] Retry mechanisms work as expected

---

This testing guide ensures comprehensive validation of all new batch processing features and maintains high quality standards for the content generation system.