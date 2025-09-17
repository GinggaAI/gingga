# Reels::SmartPlanningControllerService API Documentation

## Overview

The `SmartPlanningControllerService` processes smart planning data and applies it to reel instances. It handles JSON parsing, data validation, scene building, and graceful error recovery for smart planning integration.

## Purpose

This service encapsulates the complex logic of processing smart planning data:
- Safe JSON parsing with error handling
- Applying basic reel information (title, description)
- Processing scene data from shotplan structures
- Managing default avatar and voice assignments
- Handling partial data and missing fields gracefully

## API Reference

### Constructor

```ruby
Reels::SmartPlanningControllerService.new(
  reel: Reel,
  smart_planning_data: String,
  current_user: User
)
```

#### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `reel` | Reel | ✅ | The reel instance to apply planning data to (can be unsaved) |
| `smart_planning_data` | String | ✅ | JSON string containing planning data |
| `current_user` | User | ✅ | User for avatar/voice defaults and logging context |

### Method: `#call`

```ruby
service = Reels::SmartPlanningControllerService.new(
  reel: reel,
  smart_planning_data: json_string,
  current_user: user
)
result = service.call
```

#### Return Value

Returns a hash with the following structure:

**Success Response:**
```ruby
{
  success: true,
  error: nil
}
```

**Failure Response:**
```ruby
{
  success: false,
  error: String  # Specific error message
}
```

## Smart Planning Data Format

### Expected JSON Structure

```json
{
  "title": "Reel Title",
  "content_name": "Alternative title field",
  "description": "Reel description",
  "post_description": "Alternative description field",
  "shotplan": {
    "scenes": [
      {
        "voiceover": "Scene script content",
        "script": "Alternative script field",
        "description": "Another script field option",
        "avatar_id": "custom_avatar_123",
        "voice_id": "custom_voice_456"
      }
    ]
  }
}
```

### Field Priority

**Basic Info (applied in order of preference):**
- `title` → `content_name`
- `description` → `post_description`

**Scene Script (applied in order of preference):**
- `voiceover` → `script` → `description`

**Scene Assets:**
- `avatar_id` (uses user's default if not provided)
- `voice_id` (uses user's default if not provided)

## Usage Examples

### Basic Smart Planning Application

```ruby
planning_data = {
  title: "Product Showcase",
  description: "Highlighting key features",
  shotplan: {
    scenes: [
      { voiceover: "Welcome to our amazing product!" },
      { script: "Here are the top 3 benefits" },
      { voiceover: "Get started today!" }
    ]
  }
}.to_json

reel = user.reels.build(template: "only_avatars")
3.times { |i| reel.reel_scenes.build(scene_number: i + 1) }

service = Reels::SmartPlanningControllerService.new(
  reel: reel,
  smart_planning_data: planning_data,
  current_user: user
)

result = service.call

if result[:success]
  # Reel now has:
  # - reel.title = "Product Showcase"
  # - reel.description = "Highlighting key features"
  # - 3 scenes with scripts and default avatar/voice IDs
end
```

### Custom Avatar/Voice Assignment

```ruby
planning_data = {
  title: "Custom Demo",
  shotplan: {
    scenes: [
      {
        voiceover: "Custom avatar scene",
        avatar_id: "premium_avatar_001",
        voice_id: "premium_voice_002"
      },
      {
        script: "Default avatar scene"
        # Will use user's default avatar/voice
      }
    ]
  }
}.to_json

result = service.call
# First scene uses custom IDs, second uses defaults
```

### Error Handling

```ruby
# Invalid JSON
result = service.call
unless result[:success]
  puts result[:error] # "Invalid planning data format"
end

# Missing script content
planning_data = {
  shotplan: {
    scenes: [
      { avatar_id: "avatar_123" }, # No script - will be skipped
      { voiceover: "Valid scene" }  # Will be processed
    ]
  }
}.to_json

result = service.call
# Only 1 scene created, invalid scene skipped
```

## Behavior Details

### Scene Processing Logic

1. **Clear Existing Scenes**: Removes any existing `reel_scenes` associations
2. **Default Assets**: Retrieves user's preferred avatar/voice or system defaults
3. **Scene Iteration**: Processes each scene in the shotplan
4. **Content Validation**: Skips scenes without script content
5. **Scene Building**: Creates new scene associations with validated data

### Default Asset Resolution

```ruby
# Priority order for defaults:
user_avatar = current_user.avatars.active.first || current_user.avatars.first
user_voice = current_user.voices.active.first || current_user.voices.first

default_avatar_id = user_avatar&.avatar_id || "avatar_001"
default_voice_id = user_voice&.voice_id || "voice_001"
```

### Scene Number Assignment

- Scene numbers are assigned sequentially starting from 1
- Scene numbers reflect the original position in the shotplan array
- Skipped scenes (missing content) do NOT get sequential numbers
- This preserves the original scene structure from planning

### Error Recovery Patterns

The service is designed to be fault-tolerant:

- **Invalid JSON**: Returns failure but doesn't crash
- **Missing Fields**: Uses alternative field names or defaults
- **Invalid Scenes**: Skips bad scenes, continues processing good ones
- **Missing Assets**: Falls back to system defaults
- **Partial Data**: Applies what it can, ignores what it can't

## Performance Characteristics

- **Memory**: Low - works with existing reel associations
- **Database**: No queries (works with unsaved associations)
- **Speed**: Fast JSON parsing and object building
- **Fault Tolerance**: High - continues despite errors

## Logging & Debugging

### Debug Logs

```ruby
# Key information logged:
Rails.logger.info "🎯 Preloading smart planning data: #{planning_data.keys}"
Rails.logger.info "✅ Applied basic info to reel"
Rails.logger.info "🎬 Processing #{scenes.length} scenes"
Rails.logger.info "✅ Built scene #{scene_number}"
Rails.logger.info "🎬 Successfully built #{created_scenes}/#{scenes.length} scenes"
```

### Error Logs

```ruby
# JSON parsing errors:
Rails.logger.error "❌ Invalid JSON in smart planning data: #{e.message}"

# Scene building errors:
Rails.logger.error "❌ Failed to build scene #{scene_number}: #{e.message}"

# General errors:
Rails.logger.error "🚨 Smart planning preload failed: #{e.message}"
```

## Testing

### Test Coverage: 92% (48/52 lines)

Comprehensive test scenarios:

```ruby
# spec/services/reels/smart_planning_controller_service_spec.rb

# Coverage includes:
- ✅ Empty/nil planning data handling
- ✅ Valid data processing and application
- ✅ Invalid JSON error handling
- ✅ Scenes with missing script content
- ✅ Custom avatar/voice ID handling
- ✅ Default asset fallback behavior
- ✅ Field priority and alternative naming
- ✅ Partial scene data handling
```

### Running Tests

```bash
bundle exec rspec spec/services/reels/smart_planning_controller_service_spec.rb
```

## Error Conditions

| Condition | Behavior | Example |
|-----------|----------|---------|
| **Nil/Empty Data** | Success, no changes | `smart_planning_data: nil` |
| **Invalid JSON** | Failure with error message | `smart_planning_data: "invalid {"` |
| **Missing Script** | Scene skipped, continues processing | `{ avatar_id: "123" }` |
| **Missing Shotplan** | Basic info applied only | `{ title: "Test" }` |
| **Processing Error** | Failure with detailed error | Exception during scene building |

## Dependencies

### Internal Dependencies
- `User` model - For default avatar/voice resolution
- `Reel` model - Target for data application
- ActiveRecord associations - For scene building

### External Dependencies
- `JSON` - For parsing smart planning data
- `Rails.logger` - For debugging and error logging

## Integration Points

### Used By
- `Reels::FormSetupService` - For form initialization with planning data
- Direct usage in controller scenarios

### Data Sources
- Smart planning systems
- AI content generation services
- Planning workflow outputs

## Security Considerations

### Input Validation
- JSON parsing is wrapped in error handling
- No code execution from JSON content
- Field values are sanitized through ActiveRecord

### Data Sanitization
- Script content length limited by model validations
- Avatar/voice IDs validated against available assets
- No SQL injection risk (uses ActiveRecord)

## Performance Monitoring

### Key Metrics
- **Processing Success Rate**: Percentage of successful planning applications
- **Scene Skip Rate**: How often scenes are skipped due to missing content
- **Default Usage Rate**: How often default assets are used
- **Processing Time**: Time to parse and apply planning data

### Recommended Alerts
- High JSON parsing failure rate
- Frequent scene skipping (indicates data quality issues)
- Processing errors increasing over time

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2024-12-15 | Initial implementation from controller refactoring |

## See Also

- [FormSetupService API](./reels_form_setup_service.md) - Primary consumer of this service
- [ErrorHandlingService API](./reels_error_handling_service.md) - Error handling patterns
- [Controller Refactoring Overview](../reels_controller_refactoring.md) - Context and motivation