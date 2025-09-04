# Heygen API Integration Documentation

## Overview

This document outlines the implementation of Heygen API integration for avatar-based video creation in the Gingga application. The integration supports scene-based video generation with 3 scenes per reel.

## Architecture

### Models

#### Reel Model (`app/models/reel.rb`)
- **Purpose**: Represents a video project containing multiple scenes
- **Key Fields**:
  - `user_id`: Associated user
  - `mode`: Currently supports 'scene_based' mode only
  - `status`: draft, processing, completed, failed
  - `heygen_video_id`: Video ID from Heygen API
  - `video_url`: Final video URL (when completed)
  - `thumbnail_url`: Video thumbnail URL
  - `duration`: Video duration in seconds

#### ReelScene Model (`app/models/reel_scene.rb`)
- **Purpose**: Individual scene within a reel
- **Key Fields**:
  - `reel_id`: Parent reel
  - `scene_number`: 1, 2, or 3
  - `avatar_id`: Heygen avatar identifier
  - `voice_id`: Heygen voice identifier
  - `script`: Text content for the scene (1-5000 characters)

### Services

All Heygen services are located in `app/services/heygen/` and follow a consistent pattern:
- Accept user and additional parameters in initializer
- Validate API token exists and is valid
- Return standardized result hash: `{ success: boolean, data: hash/array, error: string }`

#### Heygen::ListAvatarsService
- **Endpoint**: `GET https://api.heygen.com/v1/avatars`
- **Caching**: Redis cache for 18 hours
- **Response Format**:
```ruby
{
  success: true,
  data: [
    {
      id: "avatar_1",
      name: "Sarah",
      preview_image_url: "https://example.com/sarah.jpg",
      gender: "female",
      is_public: true
    }
  ]
}
```

#### Heygen::ListVoicesService
- **Endpoint**: `GET https://api.heygen.com/v1/voices`
- **Features**: Client-side filtering by language, gender, age_group, accent
- **Caching**: Redis cache for 18 hours
- **Usage**: `Heygen::ListVoicesService.new(user, { language: 'English', gender: 'female' }).call`

#### Heygen::GenerateVideoService
- **Endpoint**: `POST https://api.heygen.com/v2/video/generate`
- **Prerequisites**: Reel must be ready for generation (3 complete scenes)
- **Payload**: Converts reel scenes to Heygen format with 1920x1080 resolution
- **Updates**: Sets reel status to 'processing' and stores heygen_video_id

#### Heygen::CheckVideoStatusService
- **Endpoint**: `GET https://api.heygen.com/v1/video_status/{video_id}`
- **Status Mapping**:
  - Heygen 'processing'/'pending' → 'processing'
  - Heygen 'completed'/'success' → 'completed'
  - Heygen 'failed'/'error' → 'failed'
- **Updates**: Reel status and video metadata when completed

## Authentication

All services require a valid Heygen API token from the user's `api_tokens` table:
- Provider: 'heygen'
- Valid: `is_valid` = true
- Mode: 'production' preferred, fallback to 'test'

Token validation is handled through the existing `User#active_token_for('heygen')` method.

## Caching Strategy

Redis caching is configured for API responses:
- **Development**: `redis://localhost:6379/0`
- **Cache Keys**: `heygen_avatars_{user_id}_{token_mode}`, `heygen_voices_{user_id}_{token_mode}`
- **TTL**: 18 hours for avatars and voices
- **Benefits**: Reduces API calls, improves response time

## Validation Rules

### Reel Validations
- Mode must be 'scene_based'
- Status must be one of: draft, processing, completed, failed
- Scene-based reels must have exactly 3 scenes (validated on persisted records)
- All scenes must be complete for scene-based mode

### ReelScene Validations
- Scene number must be 1, 2, or 3
- Scene number must be unique within each reel
- Avatar ID, Voice ID, and Script are required
- Script length: 1-5000 characters

## API Integration Flow

### 1. List Available Resources
```ruby
# List avatars
avatars = Heygen::ListAvatarsService.new(current_user).call

# List voices with filters
voices = Heygen::ListVoicesService.new(current_user, { language: 'English' }).call
```

### 2. Create and Configure Reel
```ruby
reel = Reel.create!(user: current_user, mode: 'scene_based')

# Add scenes
ReelScene.create!(reel: reel, scene_number: 1, avatar_id: 'avatar_1', 
                  voice_id: 'voice_1', script: 'Hello world')
ReelScene.create!(reel: reel, scene_number: 2, avatar_id: 'avatar_2', 
                  voice_id: 'voice_2', script: 'Second scene')
ReelScene.create!(reel: reel, scene_number: 3, avatar_id: 'avatar_3', 
                  voice_id: 'voice_3', script: 'Final scene')
```

### 3. Generate Video
```ruby
# Check if ready
if reel.ready_for_generation?
  result = Heygen::GenerateVideoService.new(current_user, reel).call
  # Reel status becomes 'processing'
  # reel.heygen_video_id is set
end
```

### 4. Monitor Progress
```ruby
# Check status periodically
result = Heygen::CheckVideoStatusService.new(current_user, reel).call

if result[:success] && result[:data][:status] == 'completed'
  # Video is ready
  # reel.video_url contains the final video URL
end
```

## Error Handling

All services implement comprehensive error handling:
- **API Token Missing**: Returns `{ success: false, error: 'No valid Heygen API token found' }`
- **API Call Failures**: Returns formatted error message with HTTP response details
- **Network Exceptions**: Catches StandardError and returns error message
- **Validation Failures**: Model validations prevent invalid data

## Testing

Comprehensive test coverage includes:
- **Service Tests**: HTTP mocking, error scenarios, caching behavior
- **Model Tests**: Validations, associations, custom methods
- **Factory Tests**: Valid object creation
- **Integration Scenarios**: End-to-end workflows

Test files:
- `spec/services/heygen/list_avatars_service_spec.rb`
- `spec/services/heygen/list_voices_service_spec.rb`
- `spec/services/heygen/generate_video_service_spec.rb`
- `spec/services/heygen/check_video_status_service_spec.rb`
- `spec/models/reel_spec.rb`
- `spec/models/reel_scene_spec.rb`

## Configuration

### Redis Configuration
```ruby
# config/environments/development.rb
config.cache_store = :redis_cache_store, { url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0") }

# config/environments/test.rb
config.cache_store = :null_store
```

### Environment Variables
- `REDIS_URL`: Redis connection string (optional, defaults to localhost)

## Future Enhancements

1. **Background Jobs**: Move video generation to background processing
2. **Webhooks**: Implement Heygen webhook handling for status updates
3. **Multiple Modes**: Support for additional reel modes beyond scene_based
4. **Advanced Customization**: Background images, transitions, effects
5. **Batch Operations**: Generate multiple videos simultaneously

## Security Considerations

- API tokens are encrypted at rest using Rails 7 Active Record Encryption
- Token validation occurs on every API request
- No API keys are logged or exposed in responses
- Secure Redis connections recommended for production

## Performance Notes

- Redis caching reduces API calls by ~90% for avatar/voice listings
- Background job processing recommended for video generation
- Consider rate limiting for API-intensive operations
- Monitor Heygen API quota usage

---

# Heygen Services Testing Guide (Rails Console)

This guide outlines how to manually test each of the Heygen-related service objects using real API tokens and a user context. It assumes the `BaseService` refactor is applied and endpoints are standardized.

---

## 🔐 0. Setup: Create a Valid Token

```ruby
user = User.find_by(email: "your_email@example.com")

ApiToken.create!(
  user: user,
  provider: "heygen",
  mode: "production",
  encrypted_token: ENV["HEYGEN_API_KEY"] || "paste_your_api_key_here_for_test",  # Set manually during test if not using ENV
  is_valid: true
)
```

**Note**: Ensure encryption is working and `ENV["ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY"]` is loaded.

---

## 1. 🎭 List Avatars

```ruby
result = Heygen::ListAvatarsService.new(user).call
puts result[:data] if result[:success]
```

**Expected structure:**
```ruby
# => [{ id: "avatar_id", name: "John AI", preview_image_url: "..." }, ...]
```

---

## 2. 🔊 List Voices

```ruby
result = Heygen::ListVoicesService.new(user).call
puts result[:data].map { |v| v[:name] } if result[:success]
```

**With filters:**
```ruby
result = Heygen::ListVoicesService.new(user, { language: 'English', gender: 'female' }).call
puts result[:data] if result[:success]
```

---

## 3. 🎬 Generate Video (Reel with Scenes)

**Preconditions:**
- A Reel exists
- It has 1–3 ReelScene records, each with avatar_id, voice_id, and script
- `reel.ready_for_generation?` returns true
- Each scene responds to `.to_heygen_payload`

```ruby
reel = user.reels.last
result = Heygen::GenerateVideoService.new(user, reel).call
puts result
```

**Expected:**
```ruby
{ success: true, data: { video_id: "...", status: "processing" } }
```

**If it fails:**
- Ensure avatar and voice IDs are public
- Use supported resolutions (e.g., 1280x720)

---

## 4. ⏳ Check Video Status

```ruby
result = Heygen::CheckVideoStatusService.new(user, reel).call
puts result[:data] if result[:success]
```

**If result is 404:**
- Retry after a few seconds
- Uses endpoint: `/v1/video_status.get`

---

## 5. 🧪 Retry Block (Optional)

```ruby
5.times do
  result = Heygen::CheckVideoStatusService.new(user, reel).call
  break puts(result) if result[:success]
  sleep 3
end
```

---

## 6. 📼 Download or Play the Video

Once status is `completed`, extract the video URL:

```ruby
video_url = result[:data][:video_url]
`open #{video_url}` # Or use it in your frontend
```

---

This manual testing guide validates the Heygen flow end-to-end before connecting it to frontend flows or automations (e.g., via n8n).

---

## ⚠️ Anti-Patterns to Avoid

### ❌ Environment-Dependent Behavior in Services

**NEVER** implement different behavior based on `Rails.env` within service objects, especially for API calls:

```ruby
# ❌ WRONG - Environment-dependent behavior
def call
  if Rails.env.development?
    return mock_data  # Bad practice
  end
  
  make_real_api_call
end
```

**Why This Is Bad:**
- Violates the principle that services should behave consistently across environments
- Makes testing unreliable and unpredictable
- Creates hidden behavior that's hard to debug
- Tests may pass in development but fail in production
- Breaks the Rails principle of "Convention over Configuration"

**✅ CORRECT Approach:**
```ruby
# ✅ GOOD - Consistent behavior, use VCR for testing
def call
  response = make_api_call
  parse_response(response)
end
```

**For Testing:** Use VCR (Video Cassette Recorder) to record and replay HTTP interactions:
```ruby
# spec/services/heygen/list_avatars_service_spec.rb
RSpec.describe Heygen::ListAvatarsService do
  it 'fetches avatars from API', :vcr do
    service = described_class.new(user)
    result = service.call
    expect(result[:success]).to be true
  end
end
```

### Best Practices for Service Objects:
- **Consistent behavior** across all environments
- **Use VCR for testing** external API calls
- **Dependency injection** for better testability
- **Single responsibility** - each service does one thing well
- **Proper error handling** without environment-specific logic