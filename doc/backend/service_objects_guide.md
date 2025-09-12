# Service Objects Guide

## Overview

This guide documents the service object pattern used in the Gingga Rails application, including conventions, best practices, and implementation examples based on the successful refactoring of the ReelsController.

## Service Object Pattern

### Purpose

Service objects encapsulate business logic that doesn't naturally fit in models or controllers, providing:
- **Single Responsibility**: Each service has one clear purpose
- **Better Testability**: Business logic can be tested in isolation
- **Code Reusability**: Services can be used across multiple contexts
- **Cleaner Controllers**: Controllers focus only on HTTP concerns

### When to Use Service Objects

✅ **Use service objects for:**
- Complex business logic that spans multiple models
- API integrations and external service calls
- Multi-step workflows and processes
- Form processing with complex validation
- Data transformation and formatting
- Background job coordination

❌ **Don't use service objects for:**
- Simple CRUD operations (use models directly)
- Basic view logic (use presenters or helpers)
- Single-method operations that fit naturally in models
- Configuration or constants (use proper Rails conventions)

## Implementation Conventions

### Service Structure

All services follow this standardized structure:

```ruby
module Domain
  class ActionService
    def initialize(required_param:, optional_param: nil)
      @required_param = required_param
      @optional_param = optional_param
    end

    def call
      return failure_result('Validation error') unless valid?

      # Main business logic here
      result = perform_operation

      success_result(data: result)
    rescue StandardError => e
      failure_result("Operation failed: #{e.message}")
    end

    private

    def valid?
      # Input validation logic
    end

    def perform_operation
      # Core business logic
    end

    def success_result(data: nil)
      { success: true, data: data, error: nil }
    end

    def failure_result(error_message)
      { success: false, data: nil, error: error_message }
    end
  end
end
```

### Naming Conventions

- **Module**: Domain name (e.g., `Reels`, `Planning`, `Users`)
- **Class**: Action or purpose + `Service` (e.g., `FormSetupService`, `EmailDeliveryService`)
- **Method**: Always use `#call` as the main entry point
- **Files**: `app/services/domain/action_service.rb`

### Return Value Standards

All services must return a consistent hash format:

```ruby
# Success
{
  success: true,    # Boolean indicating success
  data: Object,     # Any relevant return data
  error: nil        # No error on success
}

# Failure
{
  success: false,   # Boolean indicating failure
  data: nil,        # No data on failure
  error: String     # Human-readable error message
}
```

## Real-World Examples

### 1. FormSetupService - Form Initialization

```ruby
# Usage
service = Reels::FormSetupService.new(
  user: current_user,
  template: "only_avatars",
  smart_planning_data: json_string
)

result = service.call

if result[:success]
  @reel = result[:data][:reel]
  @presenter = result[:data][:presenter]
  render result[:data][:view_template]
else
  handle_error(result[:error])
end
```

**Key Features:**
- Builds unsaved model instances for forms
- Integrates multiple sub-services
- Returns complex data structure with multiple objects

### 2. SmartPlanningControllerService - Data Processing

```ruby
# Usage
service = Reels::SmartPlanningControllerService.new(
  reel: reel_instance,
  smart_planning_data: json_string,
  current_user: user
)

result = service.call

if result[:success]
  # Reel has been modified with planning data
else
  Rails.logger.warn "Planning failed: #{result[:error]}"
end
```

**Key Features:**
- Processes external data formats (JSON)
- Modifies existing objects in-place
- Graceful error handling with detailed logging

### 3. ErrorHandlingService - Controller Integration

```ruby
# Usage
error_handler = Reels::ErrorHandlingService.new(controller: self)
error_handler.handle_creation_error(creation_result, reel_params)
```

**Key Features:**
- Integrates with Rails controller context
- Handles multiple error response types
- Manages HTTP concerns (redirects, rendering)

## Testing Best Practices

### Test Structure

```ruby
require 'rails_helper'

RSpec.describe Domain::ActionService do
  let(:user) { create(:user) }
  let(:valid_params) { { key: 'value' } }

  describe '#call' do
    context 'with valid parameters' do
      it 'returns success with expected data' do
        service = described_class.new(user: user, params: valid_params)
        result = service.call

        expect(result[:success]).to be true
        expect(result[:data]).to be_present
        expect(result[:error]).to be_nil
      end

      it 'performs the expected business logic' do
        # Test specific behavior expectations
      end
    end

    context 'with invalid parameters' do
      it 'returns failure with error message' do
        service = described_class.new(user: user, params: {})
        result = service.call

        expect(result[:success]).to be false
        expect(result[:data]).to be_nil
        expect(result[:error]).to be_present
      end
    end

    context 'when external service fails' do
      it 'handles errors gracefully' do
        # Test error scenarios
      end
    end
  end
end
```

### Test Coverage Goals

- **Unit Tests**: Test service logic in isolation
- **Integration Tests**: Test service within full application context
- **Edge Cases**: Test error conditions and boundary cases
- **Mocking**: Mock external dependencies and APIs

## Error Handling Patterns

### Graceful Degradation

```ruby
def call
  return success_result if @data.blank? # Handle empty input gracefully

  processed_data = process_data
  return success_result(data: processed_data) if processed_data.present?

  failure_result("No data could be processed")
rescue ExternalServiceError => e
  Rails.logger.error "External service failed: #{e.message}"
  failure_result("External service unavailable")
rescue StandardError => e
  Rails.logger.error "Unexpected error: #{e.message}"
  failure_result("Operation failed")
end
```

### Input Validation

```ruby
private

def validate_inputs
  return "User required" unless @user.present?
  return "Invalid template" unless valid_template?
  return "Data format invalid" unless valid_data_format?

  nil # No validation errors
end

def valid?
  validate_inputs.nil?
end
```

## Performance Considerations

### Minimize Database Queries

```ruby
# ✅ Good - batch operations
def call
  User.includes(:avatars, :voices).where(id: user_ids).find_each do |user|
    process_user(user)
  end
end

# ❌ Bad - N+1 queries
def call
  users.each do |user|
    user.avatars.each { |avatar| process_avatar(avatar) }
  end
end
```

### Avoid Heavy Processing

```ruby
# ✅ Good - delegate heavy work to background jobs
def call
  job_id = HeavyProcessingJob.perform_later(data)
  success_result(data: { job_id: job_id })
end

# ❌ Bad - blocking operation
def call
  heavy_processing(large_dataset) # Blocks request
  success_result
end
```

## Integration Patterns

### Controller Integration

```ruby
class SomeController < ApplicationController
  def create
    result = Domain::CreateService.new(
      user: current_user,
      params: strong_params
    ).call

    if result[:success]
      redirect_to result[:data], notice: "Created successfully!"
    else
      @resource = result[:data] || Domain::Resource.new
      flash.now[:alert] = result[:error]
      render :new, status: :unprocessable_entity
    end
  end

  private

  def strong_params
    params.require(:resource).permit(:name, :description)
  end
end
```

### Background Job Integration

```ruby
class ProcessingJob < ApplicationJob
  def perform(data_id)
    data = Data.find(data_id)

    result = Domain::ProcessingService.new(data: data).call

    if result[:success]
      Rails.logger.info "Processing completed for #{data_id}"
    else
      Rails.logger.error "Processing failed for #{data_id}: #{result[:error]}"
      raise result[:error] # Re-queue the job
    end
  end
end
```

## Common Patterns

### Service Composition

```ruby
class ComplexWorkflowService
  def call
    step1_result = Step1Service.new(params: @params).call
    return step1_result unless step1_result[:success]

    step2_result = Step2Service.new(data: step1_result[:data]).call
    return step2_result unless step2_result[:success]

    success_result(data: step2_result[:data])
  end
end
```

### Conditional Processing

```ruby
class ConditionalService
  def call
    return success_result unless should_process?

    if complex_condition?
      ComplexProcessingService.new(@params).call
    else
      SimpleProcessingService.new(@params).call
    end
  end

  private

  def should_process?
    # Decision logic
  end
end
```

## Monitoring & Debugging

### Logging Standards

```ruby
def call
  Rails.logger.info "🎯 Starting #{self.class.name} with params: #{@params.keys}"

  result = perform_operation

  if result[:success]
    Rails.logger.info "✅ #{self.class.name} completed successfully"
  else
    Rails.logger.error "❌ #{self.class.name} failed: #{result[:error]}"
  end

  result
rescue StandardError => e
  Rails.logger.error "🚨 #{self.class.name} crashed: #{e.message}"
  Rails.logger.error e.backtrace.join("\n")
  failure_result("Internal error occurred")
end
```

### Metrics Collection

```ruby
def call
  start_time = Time.current

  result = perform_operation

  duration = Time.current - start_time
  Rails.logger.info "📊 #{self.class.name} duration: #{duration}s"

  # Optional: Send to metrics service
  # MetricsService.record("#{self.class.name}.duration", duration)
  # MetricsService.increment("#{self.class.name}.#{result[:success] ? 'success' : 'failure'}")

  result
end
```

## Migration Strategy

### Extracting from Controllers

1. **Identify Business Logic**: Look for complex private methods
2. **Create Service**: Extract to service object following conventions
3. **Maintain Interface**: Keep controller API unchanged initially
4. **Add Tests**: Create comprehensive service tests
5. **Refactor Controller**: Simplify controller to use service
6. **Clean Up**: Remove old private methods

### Extracting from Models

1. **Identify Multi-Model Logic**: Find methods that touch multiple models
2. **Create Service**: Extract to service with proper dependencies
3. **Update Callers**: Change calls to use new service
4. **Maintain Model API**: Keep simple model methods as facades if needed
5. **Test Coverage**: Ensure all paths are tested

## Common Pitfalls

### ❌ Over-Engineering

```ruby
# Bad - unnecessary service for simple operation
class User::NameService
  def call
    "#{@user.first_name} #{@user.last_name}"
  end
end

# Good - simple model method
class User
  def full_name
    "#{first_name} #{last_name}"
  end
end
```

### ❌ God Services

```ruby
# Bad - too many responsibilities
class UserManagementService
  def call
    create_user
    send_welcome_email
    setup_preferences
    create_billing_account
    schedule_onboarding
  end
end

# Good - focused services
class User::CreationService; end
class User::EmailService; end
class User::PreferencesService; end
```

### ❌ Leaky Abstractions

```ruby
# Bad - exposing implementation details
def call
  result = SomeModel.where(complex_query).includes(:associations)
  success_result(data: result)
end

# Good - clean interface
def call
  users = find_relevant_users
  success_result(data: users)
end
```

## Future Enhancements

### Potential Additions

1. **Service Registry**: Central registry for service discovery
2. **Service Decorators**: Cross-cutting concerns (logging, metrics, caching)
3. **Service Chains**: Declarative service composition
4. **Service Testing DSL**: Simplified testing helpers

### Integration Opportunities

1. **GraphQL Resolvers**: Use services as GraphQL field resolvers
2. **API Endpoints**: Expose services through API controllers
3. **Event Sourcing**: Services as event handlers
4. **Command Pattern**: Services as commands with undo/redo

---

This guide provides a foundation for implementing clean, maintainable service objects that follow Rails best practices and support the long-term maintainability of the Gingga application.