# HeyGen Token Validation Behavior and Replication Guide

## Overview

This document explains how the HeyGen API token validation system works in the Gingga application and provides step-by-step instructions for replicating the validation behavior for testing and development purposes.

## Architecture Components

### 1. API Response Logging System

**Model**: `ApiResponse` (`app/models/api_response.rb`)
- Stores all API calls made to external services (HeyGen, OpenAI, Kling)
- Tracks request data, response data, timing, and success/failure status
- Automatically sanitizes sensitive information (API keys)
- Provides scopes for filtering and analysis

**Database Schema**:
```sql
CREATE TABLE api_responses (
  id UUID PRIMARY KEY,
  provider VARCHAR NOT NULL,           -- 'heygen', 'openai', 'kling'
  endpoint VARCHAR NOT NULL,           -- API endpoint path
  request_data TEXT,                   -- JSON request payload/headers
  response_data TEXT,                  -- JSON response body
  status_code INTEGER,                 -- HTTP status code
  response_time_ms INTEGER,            -- Response time in milliseconds
  success BOOLEAN DEFAULT FALSE,       -- Whether call was successful
  error_message VARCHAR,               -- Error description if failed
  user_id UUID NOT NULL,              -- Associated user
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);
```

### 2. HeyGen Service Architecture

**Base Service**: `app/services/heygen/base_service.rb`
- Provides common HTTP functionality for all HeyGen services
- Automatically logs all API requests/responses via `log_api_response` method
- Handles authentication headers and error handling
- Sanitizes sensitive data before logging

**Validation Service**: `app/services/heygen/validate_key_service.rb`
- Validates HeyGen API tokens by making test API calls
- Supports development mode bypass for testing
- Logs validation attempts for debugging

**Avatar Listing Service**: `app/services/heygen/list_avatars_service.rb`
- Fetches available avatars from HeyGen API
- Provides mock data in development mode
- Caches results for performance
- Logs all API interactions

**Synchronization Service**: `app/services/heygen/synchronize_avatars_service.rb`
- Orchestrates avatar synchronization from HeyGen API
- Creates/updates Avatar records in database
- Handles duplicate detection and data mapping
- Returns structured results for UI feedback

## Token Validation Workflow

### Production Behavior

1. **Token Submission** (`SettingsController#update`)
   ```ruby
   # User submits API token via settings form
   api_token = current_user.api_tokens.find_or_initialize_by(
     provider: "heygen", mode: "production"
   )
   api_token.encrypted_token = params[:heygen_api_key]
   ```

2. **Validation Trigger** (`ApiToken#validate_token_with_provider` callback)
   ```ruby
   # Before save callback validates token
   result = ApiTokenValidatorService.new(
     provider: "heygen",
     token: encrypted_token,
     mode: mode
   ).call
   ```

3. **API Validation** (`Heygen::ValidateKeyService#call`)
   ```ruby
   # Makes actual API call to HeyGen
   response = self.class.get("/v2/avatars", {
     headers: { "X-API-KEY" => @token, "Content-Type" => "application/json" }
   })
   ```

4. **Response Logging** (Automatic via `BaseService#log_api_response`)
   ```ruby
   ApiResponse.log_api_call(
     provider: "heygen",
     endpoint: "/v2/avatars", 
     user: current_user,
     request_data: sanitized_headers,
     response_data: response.body,
     status_code: response.code,
     success: response.success?
   )
   ```

### Development Mode Behavior

**Token Pattern Matching**:
- Tokens starting with `hg_`, `test_`, or `demo_` bypass real API validation
- Mock responses are generated instead of API calls
- All interactions are still logged for consistency

**Mock Avatar Data**:
```ruby
[
  {
    id: "heygen_avatar_demo_1",
    name: "Professional Female Avatar", 
    preview_image_url: "https://via.placeholder.com/400x600/4F46E5/FFFFFF?text=Female+Avatar",
    gender: "female",
    is_public: true
  },
  # ... 2 more mock avatars
]
```

## Replication Instructions

### Step 1: Development Environment Setup

1. **Ensure Secret Key Base**:
   ```bash
   echo "SECRET_KEY_BASE=$(bundle exec rails secret)" >> .env
   ```

2. **Run Database Migrations**:
   ```bash
   bundle exec rails db:migrate
   ```

3. **Verify Environment**:
   ```bash
   bundle exec rails runner "puts Rails.env"  # Should output 'development'
   ```

### Step 2: User and Token Creation

1. **Create Test User** (via Rails console or UI):
   ```ruby
   user = User.create!(
     email: "heygen_test@example.com",
     password: "password123"
   )
   ```

2. **Create Development Token**:
   ```ruby
   # Option A: Via Rails Console
   api_token = user.api_tokens.create!(
     provider: "heygen",
     mode: "production",
     encrypted_token: "hg_development_test_token_123"  # Must start with hg_
   )
   
   # Option B: Via Settings UI
   # Navigate to /settings, fill in token starting with 'hg_', click Save
   ```

### Step 3: Validate Token and Trigger Avatar Sync

1. **Via Settings UI**:
   ```
   1. Navigate to http://localhost:3000/settings
   2. Enter token: hg_development_test_token_123
   3. Click "Save" button
   4. Verify "Configured" status appears
   5. Click "Validate" button
   6. Should see "Synchronized 3 avatars" success message
   ```

2. **Via Rails Console**:
   ```ruby
   # Verify token is valid
   token = user.active_token_for("heygen")
   puts "Token valid: #{token.is_valid}"  # Should be true
   
   # Test synchronization service
   service = Heygen::SynchronizeAvatarsService.new(user: user)
   result = service.call
   puts "Success: #{result.success?}"
   puts "Count: #{result.data[:synchronized_count]}"
   ```

### Step 4: Verify API Response Logging

1. **Check API Responses**:
   ```ruby
   # View logged API calls
   user.api_responses.recent.each do |response|
     puts "#{response.provider} #{response.endpoint}: #{response.status_code}"
     puts "Success: #{response.success?}"
     puts "Response time: #{response.response_time_ms}ms"
     puts "Error: #{response.error_message}" if response.error_message
   end
   ```

2. **Check Created Avatars**:
   ```ruby
   user.avatars.each do |avatar|
     puts "#{avatar.name} (#{avatar.gender}, #{avatar.provider})"
     puts "Active: #{avatar.active?}, Public: #{avatar.is_public}"
   end
   ```

## Testing Different Scenarios

### Valid Development Token
```ruby
# Tokens that will pass development validation
valid_tokens = [
  "hg_12345678",
  "test_heygen_token",
  "demo_development_key"
]
```

### Invalid Production Token Simulation
```ruby
# To test real API validation failure
api_token = user.api_tokens.create!(
  provider: "heygen", 
  mode: "production",
  encrypted_token: "invalid_real_token"  # Will call real API and fail
)
```

### Mock vs Real API Toggle
```ruby
# In heygen/validate_key_service.rb, modify condition:
if Rails.env.development? && false  # Change to true/false to toggle mock
```

## Debugging Common Issues

### Issue 1: Token Validation Fails
**Symptoms**: Save button works, but Validate button stays disabled
**Debug**:
```ruby
token = user.active_token_for("heygen")
puts "Token exists: #{token.present?}"
puts "Token valid: #{token&.is_valid}"
puts "Token value: #{token&.encrypted_token}"
```

### Issue 2: No Avatars Created
**Symptoms**: Validation succeeds but avatar count is 0
**Debug**:
```ruby
# Check service directly
result = Heygen::ListAvatarsService.new(user).call
puts "List service success: #{result[:success]}"
puts "Avatar data: #{result[:data]}"

# Check synchronization
sync_result = Heygen::SynchronizeAvatarsService.new(user: user).call
puts "Sync success: #{sync_result.success?}"
puts "Sync error: #{sync_result.error}" if sync_result.error
```

### Issue 3: API Responses Not Logged
**Debug**:
```ruby
# Verify APIResponse model
puts "APIResponse table exists: #{ActiveRecord::Base.connection.table_exists?('api_responses')}"
puts "Total API responses: #{ApiResponse.count}"

# Check recent responses for user
user.api_responses.recent.limit(5).each do |r|
  puts "#{r.created_at}: #{r.provider} #{r.endpoint} - #{r.success? ? 'SUCCESS' : 'FAIL'}"
end
```

## Security Considerations

1. **API Key Sanitization**: All logged request data automatically redacts API keys
2. **Development Mode Only**: Mock responses only work in development environment
3. **User Association**: All API responses are tied to specific users
4. **Data Retention**: Consider implementing cleanup policies for old API response logs

## Monitoring and Analytics

### Performance Metrics
```ruby
# Average response times by endpoint
ApiResponse.where(provider: 'heygen', success: true)
          .group(:endpoint)
          .average(:response_time_ms)

# Success rates by endpoint  
ApiResponse.where(provider: 'heygen')
          .group(:endpoint, :success)
          .count
```

### Error Analysis
```ruby
# Recent failures
ApiResponse.failed
          .where(provider: 'heygen')
          .recent
          .pluck(:endpoint, :error_message, :created_at)
```

## Integration with CI/CD

### Test Environment
- Tests use mocked responses via RSpec stubs
- No actual API calls made during automated testing
- Factory patterns provide consistent test data

### Production Deployment
- Real API validation always occurs in production
- Comprehensive logging helps debug integration issues
- Monitor API response success rates and timing

---

**Last Updated**: September 3, 2025  
**Version**: 1.0  
**Author**: Claude Code Assistant