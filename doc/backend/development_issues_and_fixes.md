# Development Issues and Fixes Guide

## Overview

This document captures common development issues encountered during the auto-creation videos interface implementation and their solutions. Use this as a reference for troubleshooting similar problems in the future.

## Test Coverage Issues

### Issue: Test Coverage Not Reflecting Actual Coverage
**Problem**: SimpleCov reporting lower coverage than expected despite comprehensive tests.
**Symptoms**:
- Coverage report shows 39% when expecting 91%+
- Tests are passing but coverage metrics don't match
- Specific methods not being marked as covered

**Root Cause**: 
- Missing test cases for private methods
- Complex conditional logic not fully exercised
- Error recovery paths not tested

**Solution**:
```ruby
# Ensure all private methods are tested indirectly
describe 'error recovery' do
  it 'handles template normalization' do
    service = described_class.new(user: user, idea: idea)
    expect(service.send(:normalize_template, 'solo_avatar')).to eq('solo_avatars')
  end
end

# Test all conditional branches
context 'when validation fails' do
  before do
    allow_any_instance_of(ContentItem).to receive(:valid?).and_return(false)
    allow_any_instance_of(ContentItem).to receive(:errors).and_return(
      double(full_messages: ['Template error'])
    )
  end
  
  it 'applies recovery fixes' do
    result = service.call
    expect(result[:success]).to be true
  end
end
```

**Prevention**: 
- Write tests for all method paths including error scenarios
- Use coverage reports to identify untested code paths
- Mock external dependencies consistently

### Issue: Test Failures Due to Missing Parameters
**Problem**: Tests failing with "undefined local variable" errors.
**Symptoms**:
```
NameError: undefined local variable or method `idea' for ...
```

**Root Cause**: Methods expecting parameters that weren't provided in test setup.

**Solution**:
```ruby
# Always provide required parameters
let(:user) { create(:user) }
let(:idea) { create(:idea, user: user) }
let(:service) { described_class.new(user: user, idea: idea) }

# Or mock the method if parameter not needed for test
before do
  allow(service).to receive(:some_method).and_return(expected_result)
end
```

## Frontend Integration Issues

### Issue: JavaScript Controller Not Receiving Rails Data
**Problem**: Stimulus controller unable to access avatar data from Rails backend.
**Symptoms**:
- Avatar dropdown shows hardcoded options
- Dynamic avatar list not populating
- Console errors about undefined values

**Root Cause**: Missing data attribute connection between Rails view and JavaScript controller.

**Solution**:
```haml
// In Rails view (scene_based.html.haml)
.scene-list{"data-controller" => "scene-list",
           "data-scene-list-scene-count-value" => @presenter.scene_count,
           "data-scene-list-avatars-value" => @presenter.avatars_for_select.to_json}
```

```javascript
// In Stimulus controller
static values = { sceneCount: Number, avatars: Array }

connect() {
  console.log('Avatars loaded:', this.avatarsValue); // Debug log
}

generateAvatarOptions() {
  if (!this.hasAvatarsValue || this.avatarsValue.length === 0) {
    return '<option value="" disabled>No avatars available...</option>';
  }
  return this.avatarsValue.map(avatar => {
    const [name, id] = avatar;
    return `<option value="${id}">${name}</option>`;
  }).join('');
}
```

**Prevention**:
- Always define static values for data you need to pass
- Use meaningful naming for data attributes
- Add debug logging during development

### Issue: Avatar Data Format Mismatch
**Problem**: JavaScript expecting different data format than Rails provides.
**Symptoms**:
- Avatar options not rendering correctly
- JavaScript errors when processing avatar array
- Inconsistent dropdown population

**Root Cause**: Rails presenter returning different format than JavaScript expects.

**Solution**:
```ruby
# Rails presenter - ensure consistent format
def avatars_for_select
  current_user.avatars.active.map do |avatar|
    [avatar.name, avatar.avatar_id] # Always return [name, id] tuple
  end
end
```

```javascript
// JavaScript - handle the expected format
generateAvatarOptions() {
  return this.avatarsValue.map(avatar => {
    const [name, id] = avatar; // Destructure tuple consistently
    return `<option value="${id}">${name}</option>`;
  }).join('');
}
```

## Service Object Issues

### Issue: Environment-Dependent Service Behavior
**Problem**: Services behaving differently in test vs development environments.
**Symptoms**:
- Tests pass but manual testing fails
- Inconsistent API responses
- Different error handling in different environments

**Root Cause**: Services using `Rails.env` conditionals instead of proper dependency injection.

**Anti-Pattern (Avoid)**:
```ruby
class SomeService
  def call
    if Rails.env.development?
      return mock_response
    end
    real_api_call
  end
end
```

**Correct Pattern**:
```ruby
class SomeService
  def initialize(http_client: Http::BaseClient.new)
    @http_client = http_client
  end

  def call
    response = @http_client.get("/api/endpoint")
    process_response(response)
  end
end

# In tests, inject mock client
let(:mock_client) { instance_double(Http::BaseClient) }
let(:service) { described_class.new(http_client: mock_client) }
```

**Prevention**:
- Always use dependency injection for external services
- Use VCR for HTTP request testing
- Avoid environment conditionals in business logic

### Issue: Inconsistent Error Handling
**Problem**: Services returning different result formats for success vs failure.
**Symptoms**:
- Controller logic becomes complex checking different response formats
- Inconsistent error messaging
- Hard to test service responses

**Root Cause**: Ad-hoc return value patterns instead of consistent result objects.

**Solution**:
```ruby
# Consistent result object pattern
class BaseService
  private

  def success_result(data:, message: nil)
    OpenStruct.new(
      success?: true,
      data: data,
      error: nil,
      message: message
    )
  end

  def failure_result(error:, data: nil)
    OpenStruct.new(
      success?: false,
      data: data,
      error: error,
      message: error
    )
  end
end

# Usage in controller
result = SomeService.new.call
if result.success?
  redirect_to somewhere_path, notice: result.message
else
  flash.now[:error] = result.error
  render :new, status: :unprocessable_content
end
```

## Database and Model Issues

### Issue: Avatar Synchronization Race Conditions
**Problem**: Multiple avatar sync requests causing duplicate or missing avatars.
**Symptoms**:
- Duplicate avatar records
- Some avatars not being created
- Database constraint errors

**Root Cause**: Lack of proper uniqueness constraints and atomic operations.

**Solution**:
```ruby
# In migration
add_index :avatars, [:user_id, :avatar_id], unique: true

# In service
def sync_avatars
  Avatar.transaction do
    current_user.avatars.update_all(active: false)
    
    external_avatars.each do |avatar_data|
      current_user.avatars.find_or_create_by(avatar_id: avatar_data[:id]) do |avatar|
        avatar.name = avatar_data[:name]
        avatar.preview_image_url = avatar_data[:preview_image_url]
        avatar.active = true
      end
    end
  end
end
```

**Prevention**:
- Always use database constraints for data integrity
- Wrap related operations in transactions
- Use `find_or_create_by` for idempotent operations

## Rails Pattern Issues

### Issue: Business Logic in Views
**Problem**: Complex conditional logic and data manipulation in view templates.
**Symptoms**:
- Views become hard to read and maintain
- Logic duplicated across multiple views
- Difficult to test view logic

**Anti-Pattern (Avoid)**:
```haml
- if current_user.avatars.active.any?
  - current_user.avatars.active.each do |avatar|
    - if avatar.preview_image_url.present?
      %option{value: avatar.avatar_id}= "#{avatar.name} (#{avatar.gender})"
- else
  %option{disabled: true}= "No avatars available"
```

**Correct Pattern (Use Presenter)**:
```ruby
# app/presenters/avatar_selection_presenter.rb
class AvatarSelectionPresenter
  def initialize(user)
    @user = user
  end

  def avatars_for_select
    return [] unless has_avatars?
    
    @user.avatars.active.map do |avatar|
      [display_name(avatar), avatar.avatar_id]
    end
  end

  def has_avatars?
    @user.avatars.active.exists?
  end

  private

  def display_name(avatar)
    name = avatar.name
    name += " (#{avatar.gender})" if avatar.gender.present?
    name
  end
end
```

```haml
- if @presenter.has_avatars?
  - @presenter.avatars_for_select.each do |name, id|
    %option{value: id}= name
- else
  %option{disabled: true}= t('avatars.none_available')
```

**Prevention**:
- Move all conditional logic to presenters
- Keep views focused on display only
- Use helpers for formatting logic

## Testing Best Practices Learned

### Comprehensive Error Scenario Testing
```ruby
describe 'error handling' do
  context 'when API returns 404' do
    before do
      stub_request(:get, /api/).to_return(status: 404)
    end

    it 'handles not found gracefully' do
      result = service.call
      expect(result.success?).to be false
      expect(result.error).to include('not found')
    end
  end

  context 'when network timeout occurs' do
    before do
      stub_request(:get, /api/).to_timeout
    end

    it 'retries and eventually fails with timeout error' do
      result = service.call
      expect(result.success?).to be false
      expect(result.error).to include('timeout')
    end
  end
end
```

### Factory Pattern for Complex Objects
```ruby
# spec/factories/content_items.rb
FactoryBot.define do
  factory :content_item do
    association :user
    association :idea
    
    trait :with_validation_errors do
      after(:build) do |item|
        item.define_singleton_method(:valid?) { false }
        errors = double('errors')
        allow(errors).to receive(:full_messages).and_return(['Template invalid'])
        allow(item).to receive(:errors).and_return(errors)
      end
    end
  end
end

# Usage in tests
let(:invalid_item) { build(:content_item, :with_validation_errors) }
```

### Mocking External Services
```ruby
# Always use VCR for external HTTP requests
describe 'API integration' do
  it 'fetches avatar data', :vcr do
    result = service.sync_avatars
    expect(result.success?).to be true
  end
end

# For unit tests, mock at the boundary
let(:mock_response) do
  {
    avatars: [
      { id: 'avatar_1', name: 'John', preview_image_url: 'http://example.com/1.jpg' }
    ]
  }
end

before do
  allow(http_client).to receive(:get).and_return(mock_response)
end
```

## Conclusion

This document should be updated whenever new issues are encountered and resolved. The patterns and solutions here represent battle-tested approaches for common development challenges in Rails applications.

### Key Takeaways
1. **Always use dependency injection** for external services
2. **Implement consistent result objects** for service return values
3. **Use presenters** to keep business logic out of views
4. **Write comprehensive tests** including error scenarios
5. **Follow Rails conventions** for predictable, maintainable code
6. **Use database constraints** for data integrity
7. **Test edge cases and error conditions** thoroughly

---
*Last Updated: September 8, 2025*
*Document Version: 1.0*