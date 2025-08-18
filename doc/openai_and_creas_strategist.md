# OpenAI and CREAS Strategist Integration

## Overview

This document describes the OpenAI integration and CREAS (Content, Retention, Engagement, Activation, Satisfaction) strategist system that was added to the Gingga platform. The system enables AI-powered strategy generation for brand content planning using OpenAI's GPT models.

## What Was Added

### 1. Database Schema Extensions

**New Tables:**
- `brands` - Core brand information with industry, voice, and configuration
- `audiences` - Target audience demographics and behavioral data
- `products` - Brand products with descriptions and positioning
- `brand_channels` - Social media channels and platform priorities  
- `creas_strategy_plans` - Generated AI strategy plans with full metadata
- `creas_posts` - Individual post ideas generated from strategies

**Key Features:**
- UUID primary keys for all new tables
- JSONB fields with GIN indexes for efficient querying
- Comprehensive associations between all entities
- Validation rules and defaults for data integrity

### 2. OpenAI Integration Services

**GinggaOpenAI Module:**
- `ClientForUser` - Per-user API token management with ENV fallback
- `ChatClient` - Robust JSON-mode chat client with retry logic and error handling
- `ValidateKeyService` - API key validation service

**Key Features:**
- User-specific OpenAI tokens stored securely in `api_tokens` table
- Automatic fallback to environment variables when user tokens unavailable
- JSON mode enforcement to ensure structured responses
- Comprehensive error handling and retry logic

### 3. CREAS Strategy Framework

**Creas Module:**
- `Prompts` - Complete prompt engineering for strategy generation
- `NoctuaStrategyService` - Main service for generating and persisting strategies

**Strategy Components:**
- **C**ontent Distribution (Growth-focused content planning)
- **R**etention strategies (Audience engagement and loyalty)
- **E**ngagement tactics (Community building and interaction)
- **A**ctivation campaigns (Converting followers to customers)
- **S**atisfaction metrics (Customer experience optimization)

### 4. API Endpoints

**CreasStrategistController:**
- `POST /creas_strategist` - Generate new strategy plans
- Comprehensive parameter validation
- Error handling with appropriate HTTP status codes
- JSON response format with full strategy data

### 5. Data Assembly and Serialization

**NoctuaBriefAssembler:**
- Centralizes brand data collection for GPT input
- Optimized queries to avoid N+1 problems
- Structured data format for consistent AI processing

## Configuration Steps

### 1. Environment Setup

Add your OpenAI API key to your environment:

```bash
# .env or environment variables
OPENAI_API_KEY=sk-your-openai-api-key-here
```

### 2. Database Migration

Run the database migrations to create the new schema:

```bash
bundle exec rails db:migrate
```

### 3. Seed Development Data

Create sample data for testing:

```bash
bundle exec rails db:seed
```

This will create:
- Sample brands with realistic industry data
- Target audiences with demographic profiles
- Products with descriptions and positioning
- Brand channels with platform priorities

### 4. User API Token Setup (Optional)

Users can optionally configure their own OpenAI tokens for personalized usage:

1. Navigate to API tokens management (when UI is implemented)
2. Add OpenAI token with provider "openai" and mode "production"
3. The system will validate the token before saving

## Manual Testing Guide

### Step 1: Verify Database Schema

```bash
# Check that all tables were created
bundle exec rails runner "
puts 'Brands: ' + Brand.count.to_s
puts 'Audiences: ' + Audience.count.to_s  
puts 'Products: ' + Product.count.to_s
puts 'Brand Channels: ' + BrandChannel.count.to_s
puts 'Strategy Plans: ' + CreasStrategyPlan.count.to_s
"
```

### Step 2: Test Data Assembly

```bash
# Test the brief assembler service
bundle exec rails runner "
brand = Brand.first
brief = NoctuaBriefAssembler.call(
  brand: brand,
  strategy_form: {
    objective_of_the_month: 'awareness',
    frequency_per_week: 4,
    monthly_themes: ['product launch', 'behind the scenes']
  }
)
puts brief.to_json
"
```

### Step 3: Test OpenAI Client

```bash
# Test user token retrieval
bundle exec rails runner "
user = User.first
token = GinggaOpenAI::ClientForUser.access_token_for(user)
puts 'Using token: ' + (token ? 'Found' : 'None')
"
```

### Step 4: Test Strategy Generation

```bash
# Generate a complete strategy plan with error handling
bundle exec rails runner "
begin
  puts 'Testing OpenAI API connectivity...'
  
  user = User.first
  if user.nil?
    puts 'No users found. Please run: bundle exec rails db:seed'
    exit
  end
  
  brand = user.brands.first
  if brand.nil?
    puts 'No brands found for user. Creating a test brand...'
    brand = user.brands.create!(
      name: 'Test Brand',
      slug: 'test-brand',
      industry: 'Technology',
      voice: 'Professional and approachable'
    )
  end

  # Ensure brand has associated data
  if brand.audiences.empty?
    puts 'Creating test audience...'
    brand.audiences.create!(
      demographic_profile: 'Young professionals aged 25-35',
      interests: ['technology', 'productivity', 'lifestyle'],
      digital_behavior: 'Active on Instagram and LinkedIn'
    )
  end

  if brand.products.empty?
    puts 'Creating test product...'
    brand.products.create!(
      name: 'Test Product',
      description: 'A revolutionary productivity tool'
    )
  end

  if brand.brand_channels.empty?
    puts 'Creating test brand channel...'
    brand.brand_channels.create!(
      platform: 'instagram',
      handle: '@testbrand',
      priority: 1
    )
  end

  puts 'Assembling brand brief...'
  brief = NoctuaBriefAssembler.call(
    brand: brand,
    strategy_form: {
      objective_of_the_month: 'awareness',
      frequency_per_week: 4,
      monthly_themes: ['innovation', 'community']
    }
  )

  puts 'Calling OpenAI API to generate strategy... (this may take 30-60 seconds)'
  strategy = Creas::NoctuaStrategyService.new(
    user: user,
    brief: brief,
    brand: brand,
    month: '2025-08'
  ).call

  puts '✅ Success! Strategy created:'
  puts '- ID: ' + strategy.id
  puts '- Name: ' + strategy.strategy_name
  puts '- Objective: ' + strategy.objective_of_the_month
  puts '- Frequency: ' + strategy.frequency_per_week.to_s + ' posts/week'
  puts '- Themes: ' + strategy.monthly_themes.join(', ')

rescue => e
  puts '❌ Error occurred:'
  puts '- Error class: ' + e.class.name
  puts '- Error message: ' + e.message
  
  if e.message.include?('timeout') || e.is_a?(Faraday::TimeoutError)
    puts ''
    puts 'This appears to be a network timeout. Try:'
    puts '1. Check your internet connection'
    puts '2. Verify your OpenAI API key with: curl -H \"Authorization: Bearer \$OPENAI_API_KEY\" https://api.openai.com/v1/models'
    puts '3. Check OpenAI status at: https://status.openai.com/'
    puts '4. Try running the command again (automatic retry is included)'
  elsif e.message.include?('API key')
    puts ''
    puts 'This appears to be an API key issue. Please:'
    puts '1. Ensure OPENAI_API_KEY environment variable is set'
    puts '2. Verify your API key is valid and has sufficient quota'
  end
end
"
```

### Step 5: Test API Endpoint

Using curl or a tool like Postman:

```bash
# Create a strategy via API
curl -X POST http://localhost:3000/creas_strategist \
  -H "Content-Type: application/json" \
  -d '{
    "brand_id": "YOUR_BRAND_UUID",
    "month": "2025-08", 
    "objective_of_the_month": "awareness",
    "frequency_per_week": 4,
    "monthly_themes": ["innovation", "community"],
    "resources_override": {
      "ai_avatars": true,
      "editing": true
    }
  }'
```

Replace `YOUR_BRAND_UUID` with an actual brand ID from your database.

### Step 6: Verify Strategy Data

```bash
# Check the generated strategy plan
bundle exec rails runner "
plan = CreasStrategyPlan.last
puts 'Latest Strategy Plan:'
puts '- ID: ' + plan.id
puts '- Brand: ' + plan.brand.name
puts '- Month: ' + plan.month
puts '- Objective: ' + plan.objective_of_the_month
puts '- Frequency: ' + plan.frequency_per_week.to_s + ' posts/week'
puts '- Themes: ' + plan.monthly_themes.join(', ')
puts '- Raw Payload Keys: ' + plan.raw_payload.keys.join(', ')
puts '- Brand Snapshot Keys: ' + plan.brand_snapshot.keys.join(', ')
puts '- Meta: ' + plan.meta.to_json
"
```

## Testing Framework

### Automated Tests

The system includes comprehensive test coverage:

```bash
# Run all OpenAI integration tests
bundle exec rspec spec/services/gingga_openai/ \
                  spec/services/creas/ \
                  spec/requests/creas_strategist_spec.rb
```

### Test Coverage Areas

1. **Service Layer Tests:**
   - User token management and fallbacks
   - OpenAI API communication and error handling
   - Strategy generation and data persistence
   - Brief assembly and data serialization

2. **Controller Tests:**
   - Parameter validation and error responses
   - Successful strategy creation workflows
   - Authentication and authorization
   - JSON response formatting

3. **Model Tests:**
   - Database validations and constraints
   - Association integrity
   - JSONB field defaults and structure

## Architecture Notes

### Design Patterns

1. **Service-Oriented Architecture:** Core business logic separated into focused service classes
2. **Factory Pattern:** FactoryBot for consistent test data generation
3. **Assembler Pattern:** Centralized data collection for AI input
4. **Strategy Pattern:** Different AI models and prompts through configurable services

### Security Considerations

1. **Token Encryption:** User API tokens stored encrypted in database
2. **Input Validation:** Comprehensive parameter validation before processing
3. **Error Handling:** Graceful degradation without exposing sensitive information
4. **Rate Limiting:** Built-in retry logic prevents API abuse

### Performance Optimizations

1. **Database Indexes:** GIN indexes on JSONB fields for fast queries
2. **Query Optimization:** Includes() used to prevent N+1 queries
3. **Caching Strategy:** Brief assembly optimized for repeated access
4. **Async Processing:** Service architecture ready for background job integration

## Troubleshooting

### Common Issues

1. **Missing OpenAI Token:**
   - Ensure `OPENAI_API_KEY` environment variable is set
   - Check user has valid API token in database

2. **Network Timeout Errors (Faraday::TimeoutError):**
   - **Problem:** `Net::ReadTimeout` or `Faraday::TimeoutError` when connecting to OpenAI API
   - **Solutions:**
     - Check your internet connection
     - Verify your OpenAI API key is valid and has quota remaining
     - Try running the test again (the system now has automatic retry with exponential backoff)
     - Check OpenAI API status at https://status.openai.com/
   - **Quick Test:** Try a simple API connectivity test:
     ```bash
     curl -H "Authorization: Bearer $OPENAI_API_KEY" https://api.openai.com/v1/models
     ```

3. **Strategy Generation Fails:**
   - Verify brand has associated audiences, products, and channels
   - Check OpenAI API quota and rate limits
   - Review error logs for specific API responses
   - Ensure the brand data is complete before attempting strategy generation

4. **Database Errors:**
   - Ensure all migrations have been run
   - Check for required field validations
   - Verify UUID extension is enabled

### Debug Commands

```bash
# Check environment configuration
bundle exec rails runner "puts ENV['OPENAI_API_KEY'] ? 'API key configured' : 'No API key'"

# Verify database schema
bundle exec rails runner "ActiveRecord::Base.connection.tables.select { |t| t.match(/brand|audience|product|creas/) }"

# Test OpenAI connectivity
bundle exec rails runner "
client = GinggaOpenAI::ChatClient.new(user: User.first, model: 'gpt-4o-mini')
response = client.chat!(system: 'You are a helpful assistant.', user: 'Say hello')
puts response
"
```

## Next Steps

The OpenAI integration foundation is now complete. Recommended next development phases:

1. **Phase 4:** Voxa Posts Generation Service (individual post creation from strategies)
2. **Phase 5:** Hotwire UI Components (brand forms, planning interface)
3. **Phase 6:** Real-time Strategy Updates (WebSocket integration)
4. **Phase 7:** Analytics and Performance Tracking (strategy effectiveness metrics)

This system provides a robust foundation for AI-powered content strategy generation with room for extensive customization and expansion.