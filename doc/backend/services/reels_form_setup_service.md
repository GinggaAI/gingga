# Reels::FormSetupService API Documentation

## Overview

The `FormSetupService` is responsible for setting up reel forms in the `ReelsController#new` action. It handles form initialization, scene building, smart planning data application, and presenter setup.

## Purpose

This service encapsulates all the logic needed to prepare a reel form for display, including:
- Creating unsaved reel instances for forms
- Building appropriate scene structures based on template type
- Applying smart planning data when provided
- Setting up the correct presenter for rendering

## API Reference

### Constructor

```ruby
Reels::FormSetupService.new(
  user: User,
  template: String,
  smart_planning_data: String (optional)
)
```

#### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `user` | User | ✅ | The current user creating the reel |
| `template` | String | ✅ | Template type (e.g., "only_avatars", "avatar_and_video", "narration_over_7_images") |
| `smart_planning_data` | String | ❌ | JSON string containing smart planning data |

#### Supported Templates

- `"only_avatars"` - Scene-based template, builds 3 scenes
- `"avatar_and_video"` - Scene-based template, builds 3 scenes
- `"narration_over_7_images"` - Narrative template, no scenes built
- `"one_to_three_videos"` - Video-based template, no scenes built

### Method: `#call`

```ruby
service = Reels::FormSetupService.new(user: user, template: "only_avatars")
result = service.call
```

#### Return Value

Returns a hash with the following structure:

**Success Response:**
```ruby
{
  success: true,
  data: {
    reel: Reel,           # Unsaved reel instance with built associations
    presenter: Object,     # Presenter instance for the template
    view_template: String  # Rails template path for rendering
  },
  error: nil
}
```

**Failure Response:**
```ruby
{
  success: false,
  data: nil,
  error: String  # Error message describing what went wrong
}
```

## Usage Examples

### Basic Form Setup

```ruby
# Setup form for scene-based template
service = Reels::FormSetupService.new(
  user: current_user,
  template: "only_avatars"
)

result = service.call

if result[:success]
  @reel = result[:data][:reel]
  @presenter = result[:data][:presenter]
  render result[:data][:view_template]
else
  redirect_to reels_path, alert: result[:error]
end
```

### With Smart Planning Data

```ruby
smart_planning_json = {
  title: "AI Generated Reel",
  description: "Product showcase video",
  shotplan: {
    scenes: [
      { voiceover: "Welcome to our product", avatar_id: "avatar_123" },
      { voiceover: "Here are the key features" },
      { voiceover: "Contact us today!" }
    ]
  }
}.to_json

service = Reels::FormSetupService.new(
  user: current_user,
  template: "only_avatars",
  smart_planning_data: smart_planning_json
)

result = service.call
# Reel will be pre-populated with planning data
```

### Error Handling

```ruby
service = Reels::FormSetupService.new(
  user: current_user,
  template: "invalid_template"
)

result = service.call

unless result[:success]
  Rails.logger.error "Form setup failed: #{result[:error]}"
  # Handle error appropriately
end
```

## Behavior Details

### Scene Building Logic

For scene-based templates (`only_avatars`, `avatar_and_video`):
- Creates 3 empty scenes with `scene_number` 1, 2, 3
- Scenes are built as associations, not persisted to database
- Scene structure ready for form input

For non-scene-based templates:
- No scenes are created
- Reel is prepared for narrative or video-based input

### Smart Planning Integration

When `smart_planning_data` is provided:
1. **Basic Info**: Applies `title` and `description` to reel
2. **Scene Data**: Processes `shotplan.scenes` array if present
3. **Scene Mapping**: Maps planning scenes to reel scenes
4. **Fallbacks**: Uses default avatar/voice IDs when not specified
5. **Validation**: Skips scenes without script content

### Presenter Setup

Automatically determines and configures the appropriate presenter:
- Uses `Reels::PresenterService` to get the right presenter class
- Handles template-specific presenter initialization
- Returns the configured presenter ready for view rendering

### Error Conditions

The service can fail in these scenarios:
- **Invalid template**: Template not supported by presenter service
- **User not provided**: Service requires valid user instance
- **Presenter failure**: Presenter service fails to setup
- **Smart planning errors**: JSON parsing or data application failures

## Performance Characteristics

- **Memory**: Minimal - creates unsaved ActiveRecord objects
- **Database**: No queries executed (objects not persisted)
- **Speed**: Fast - primarily object initialization and JSON parsing
- **Caching**: No caching implemented (stateless service)

## Testing

### Test Coverage: 91% (30/33 lines)

The service is comprehensively tested with:

```ruby
# spec/services/reels/form_setup_service_spec.rb

# Test scenarios:
- ✅ Valid template with scene building
- ✅ Non-scene-based template handling
- ✅ Smart planning data application
- ✅ Invalid template error handling
- ✅ JSON parsing error scenarios
- ✅ Presenter setup verification
```

### Running Tests

```bash
bundle exec rspec spec/services/reels/form_setup_service_spec.rb
```

## Dependencies

### Internal Dependencies
- `Reels::SmartPlanningControllerService` - For processing smart planning data
- `Reels::PresenterService` - For setting up view presenters
- `User` model - For reel association
- `Reel` model - For form object creation

### External Dependencies
- Rails ActiveRecord for object building
- JSON for smart planning data parsing
- Rails logger for error logging

## Integration Points

### Used By
- `ReelsController#new` - Primary usage for form setup

### Collaborates With
- `SmartPlanningControllerService` - Delegates smart planning processing
- `PresenterService` - Delegates presenter configuration
- `ErrorHandlingService` - Used by controller for error responses

## Monitoring & Debugging

### Logging
The service logs the following events:
```ruby
# Smart planning errors are logged by SmartPlanningControllerService
# General service failures are logged with full error details
Rails.logger.error "🚨 Form setup failed: #{e.message}"
```

### Key Metrics to Monitor
- **Success Rate**: Percentage of successful form setups
- **Template Distribution**: Which templates are most used
- **Smart Planning Usage**: How often smart planning data is provided
- **Error Patterns**: Common failure scenarios

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2024-12-15 | Initial implementation from controller refactoring |

## See Also

- [SmartPlanningControllerService API](./reels_smart_planning_controller_service.md)
- [ErrorHandlingService API](./reels_error_handling_service.md)
- [Controller Refactoring Overview](../reels_controller_refactoring.md)