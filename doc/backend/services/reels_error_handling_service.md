# Reels::ErrorHandlingService API Documentation

## Overview

The `ErrorHandlingService` provides centralized, consistent error handling patterns for the `ReelsController`. It standardizes error responses, form re-rendering, and user feedback across all controller actions.

## Purpose

This service encapsulates error handling logic to:
- Provide consistent error response patterns across actions
- Handle form validation errors with proper rendering
- Manage JSON error responses for API-style errors
- Standardize redirect patterns for different error types
- Setup error presenters consistently

## API Reference

### Constructor

```ruby
Reels::ErrorHandlingService.new(controller: ReelsController)
```

#### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `controller` | ReelsController | ✅ | The controller instance to handle errors for |

### Methods

#### `#handle_creation_error(creation_result, reel_params)`

Handles errors from reel creation attempts.

```ruby
error_handler.handle_creation_error(creation_result, reel_params)
```

**Parameters:**
- `creation_result`: Hash result from `ReelCreationService`
- `reel_params`: Hash of reel parameters for fallback template detection

**Behavior:**
- Sets up error presenter for form re-rendering
- Renders form with validation errors if presenter succeeds
- Falls back to JSON error response if presenter fails
- Uses `422 Unprocessable Entity` status for all error responses

#### `#handle_form_setup_error(error_message)`

Handles errors from form setup failures.

```ruby
error_handler.handle_form_setup_error("Form setup failed")
```

**Parameters:**
- `error_message`: String describing the error

**Behavior:**
- Redirects to reels index with alert message
- Used for errors that prevent form display

#### `#handle_edit_access_error()`

Handles unauthorized edit access attempts.

```ruby
error_handler.handle_edit_access_error()
```

**Behavior:**
- Redirects to reels index with access denied message
- Used when non-draft reels are accessed for editing

## Usage Examples

### Form Creation Errors

```ruby
def create
  creation_result = ReelCreationService.new(
    user: current_user,
    params: reel_params
  ).call

  if creation_result[:success]
    redirect_to creation_result[:reel], notice: "Success!"
  else
    # Delegate error handling to service
    error_handler.handle_creation_error(creation_result, reel_params)
  end
end
```

### Form Setup Errors

```ruby
def new
  form_result = Reels::FormSetupService.new(
    user: current_user,
    template: params[:template]
  ).call

  if form_result[:success]
    # Render form
  else
    # Delegate error handling to service
    error_handler.handle_form_setup_error(form_result[:error])
  end
end
```

### Edit Access Errors

```ruby
def edit
  return error_handler.handle_edit_access_error unless @reel.status == "draft"

  # Continue with edit logic
end
```

## Error Response Patterns

### Form Validation Errors

When presenter setup succeeds, renders form with errors:

```ruby
# Response characteristics:
- Status: 422 Unprocessable Entity
- Content-Type: text/html
- Body: Rendered form template with error messages
- Instance variables set: @reel, @presenter
```

### Presenter Failures

When presenter setup fails, returns JSON error:

```ruby
# Response characteristics:
- Status: 422 Unprocessable Entity
- Content-Type: application/json
- Body: {"error": "Error message"}
```

### Access Errors

For unauthorized access attempts:

```ruby
# Response characteristics:
- Status: 302 Found (redirect)
- Location: /reels (index page)
- Flash: alert message
```

## Behavior Details

### Error Flow Decision Tree

```
Creation Error
├─ Setup Error Presenter
│  ├─ Success → Render Form (422)
│  └─ Failure → JSON Error (422)
│
Form Setup Error
└─ Redirect with Alert (302)

Edit Access Error
└─ Redirect with Alert (302)
```

### Template Resolution

For form re-rendering:
1. Extract template from failed reel or fallback to params
2. Setup presenter with error context
3. Use presenter's view template for rendering
4. Pass reel with validation errors to view

### Instance Variable Management

The service manages controller instance variables:
- `@reel`: Set to failed reel instance with errors
- `@presenter`: Set to configured presenter for template
- Other variables preserved from original request

## Error Message Examples

### Common Error Scenarios

```ruby
# Invalid template
"Unknown template: invalid_template"

# Form setup failure
"Failed to setup form: Template not supported"

# Edit access denied
"Only draft reels can be edited"

# Presenter failure
"Failed to setup presenter: Unknown template: xyz"
```

## Performance Characteristics

- **Speed**: Fast - primarily error response formatting
- **Memory**: Minimal - reuses existing objects where possible
- **Network**: Single response per error (no additional requests)
- **User Experience**: Preserves form data and provides clear feedback

## Testing

### Test Coverage: 75% (18/24 lines)

The service includes tests for:

```ruby
# Error handling scenarios:
- ✅ Creation errors with successful presenter setup
- ✅ Creation errors with presenter failures
- ✅ Form setup error redirects
- ✅ Edit access error redirects
- ✅ Instance variable setting
- ✅ Status code verification
```

### Running Tests

```bash
bundle exec rspec spec/services/reels/error_handling_service_spec.rb
```

## Dependencies

### Internal Dependencies
- `Reels::PresenterService` - For error presenter setup
- `ReelsController` - The controller being handled
- Rails routing helpers - For redirect paths

### External Dependencies
- Rails ActionController - For rendering and redirects
- Rails Flash - For alert messages
- Rails Status Codes - For HTTP response status

## Integration Points

### Used By
- `ReelsController#create` - For creation error handling
- `ReelsController#new` - For form setup error handling
- `ReelsController#edit` - For access control errors

### Collaborates With
- `PresenterService` - For setting up error presentation
- Flash system - For user feedback messages
- Rails rendering system - For form re-display

## Security Considerations

### Error Information Disclosure
- Error messages are user-friendly, not system-internal
- No sensitive information leaked in error responses
- Stack traces not exposed to users

### Error Response Consistency
- All errors follow consistent status code patterns
- No information leakage through different error types
- Proper HTTP status codes for each scenario

## HTTP Status Codes Used

| Scenario | Status Code | Reason |
|----------|-------------|---------|
| **Form Validation Errors** | `422 Unprocessable Entity` | Standard Rails validation error status |
| **Presenter Failures** | `422 Unprocessable Entity` | Consistent with validation errors |
| **Access Denied** | `302 Found` | Redirect to safe location |
| **Form Setup Errors** | `302 Found` | Redirect to safe location |

## Error Categorization

### User Errors (422 responses)
- Invalid form data
- Validation failures
- Business rule violations

### System Errors (302 redirects)
- Template configuration issues
- Presenter setup failures
- Access control violations

## Monitoring & Alerting

### Key Metrics to Monitor
- **Error Rate**: Percentage of requests resulting in errors
- **Error Distribution**: Which error types are most common
- **Presenter Failure Rate**: How often presenter setup fails
- **User Impact**: Which errors affect user experience most

### Recommended Alerts
- High error rate (> 5% of requests)
- Frequent presenter failures (indicates configuration issues)
- Unusual error patterns (potential system problems)

## Customization Points

### Error Message Customization
Error messages can be customized by:
- Modifying the service methods for different message patterns
- Adding internationalization (i18n) support
- Implementing user-role-specific messages

### Response Format Customization
The service can be extended to support:
- Different content types (XML, etc.)
- Custom error page templates
- Enhanced error metadata

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2024-12-15 | Initial implementation from controller refactoring |

## See Also

- [FormSetupService API](./reels_form_setup_service.md) - Primary error source for form setup
- [SmartPlanningControllerService API](./reels_smart_planning_controller_service.md) - Can generate errors for handling
- [Controller Refactoring Overview](../reels_controller_refactoring.md) - Context and error handling motivation