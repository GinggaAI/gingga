# Internationalization (i18n) Testing Guide

## Overview

This document provides comprehensive testing procedures for the internationalization features implemented in the Gingga application, including the language switcher component and multilingual content support.

---

## 🌐 **Features Implemented**

### 1. **Language Switcher Component**
- `app/components/ui/language_switcher_component.rb` - UI component for language switching
- Supports English (en) and Spanish (es) locales
- Intelligent URL path handling with locale prefixes

### 2. **Locale Configuration**
- `config/locales/en.yml` - English translations
- `config/locales/es.yml` - Spanish translations  
- Proper locale routing and path generation

### 3. **URL Handling**
- Automatic locale prefix handling (`/`, `/es/path`)
- Maintains user context during language switches
- Default locale (English) routing optimization

---

## 🧪 **Automated Testing**

### **1. Language Switcher Component Tests**
```bash
# Run language switcher component tests
bundle exec rspec spec/components/ui/language_switcher_component_spec.rb

# Should achieve 96%+ test coverage
# Tests include:
# - Component rendering in different locales
# - Path generation logic
# - Error handling scenarios
# - Edge cases and complex path scenarios
```

### **2. Component Test Coverage Verification**
```bash
# Generate coverage report and verify language switcher coverage
bundle exec rspec spec/components/ui/language_switcher_component_spec.rb
open coverage/index.html

# Expected coverage: 96%+ (24/25 lines covered)
```

---

## 🔧 **Manual Testing Procedures**

### **1. Basic Language Switching Test**

#### **Setup:**
1. Start the Rails server: `bin/dev`
2. Navigate to any application page (e.g., `/plannings`)

#### **Test Steps:**
```
1. Verify default locale (English):
   - URL should be `/plannings` (no locale prefix)
   - Interface should display in English
   - Language switcher should show "Language" label

2. Switch to Spanish:
   - Click "Spanish" in language switcher
   - URL should change to `/es/plannings`
   - Interface should display in Spanish  
   - Language switcher should show "Idioma" label

3. Switch back to English:
   - Click "English" in language switcher
   - URL should change back to `/plannings` (no prefix)
   - Interface should display in English
```

### **2. URL Path Handling Test**

#### **Test Complex Path Scenarios:**
```
1. Navigate to a nested path in English:
   - Visit `/plannings/123/edit`
   - Switch to Spanish
   - Should redirect to `/es/plannings/123/edit`

2. Test Spanish-to-English switching:
   - Visit `/es/complex/nested/path`
   - Switch to English
   - Should redirect to `/complex/nested/path` (no prefix)

3. Test empty path handling:
   - Visit `/` (root)
   - Switch to Spanish: should go to `/es/`
   - Switch back to English: should go to `/`
```

### **3. Edge Case Testing**

#### **Browser Navigation:**
```
1. Test browser back/forward:
   - Switch languages
   - Use browser back button
   - Verify correct locale and content display

2. Test direct URL access:
   - Directly access `/es/plannings`
   - Verify Spanish interface loads
   - Verify language switcher shows correct state

3. Test invalid locale URLs:
   - Try accessing `/fr/plannings` (unsupported locale)
   - Should handle gracefully (likely redirect or 404)
```

---

## 🧪 **Rails Console Testing**

### **1. Locale Configuration Testing**
```ruby
# Test available locales
puts "Available locales: #{I18n.available_locales}"
# Expected: [:en, :es]

# Test default locale
puts "Default locale: #{I18n.default_locale}"
# Expected: :en

# Test current locale
puts "Current locale: #{I18n.locale}"
# Should change based on request context
```

### **2. Translation Testing**
```ruby
# Test English translations
I18n.locale = :en
puts I18n.t("nav.english")    # Expected: "English"
puts I18n.t("nav.spanish")    # Expected: "Spanish"
puts I18n.t("nav.language")   # Expected: "Language"

# Test Spanish translations  
I18n.locale = :es
puts I18n.t("nav.english")    # Expected: "Inglés"
puts I18n.t("nav.spanish")    # Expected: "Español"
puts I18n.t("nav.language")   # Expected: "Idioma"

# Test missing translations (should handle gracefully)
begin
  I18n.t("nav.missing_key", raise: true)
rescue I18n::MissingTranslationData => e
  puts "Missing translation handled: #{e.message}"
end
```

### **3. Language Switcher Component Testing**
```ruby
# Test component initialization
component = Ui::LanguageSwitcherComponent.new
puts "Default locale: #{component.instance_variable_get(:@current_locale)}"

# Test with custom locale
component_es = Ui::LanguageSwitcherComponent.new(current_locale: :es)
puts "Custom locale: #{component_es.instance_variable_get(:@current_locale)}"

# Test available locales method
component.define_singleton_method(:test_available_locales) do
  send(:available_locales)
end
locales = component.test_available_locales
puts "Available locales structure:"
locales.each { |locale| puts "  #{locale}" }
```

### **4. Path Generation Testing**
```ruby
# Test path generation without request context
component = Ui::LanguageSwitcherComponent.new(current_locale: :en)

# Test default locale path
path_en = component.send(:switch_locale_path, 'en')
puts "English path: #{path_en}"  # Expected: "/"

# Test non-default locale path  
path_es = component.send(:switch_locale_path, 'es')
puts "Spanish path: #{path_es}"   # Expected: "/es/"

# Test with mock request context
mock_request = double(path: '/en/complex/path', present?: true)
allow(component).to receive(:request).and_return(mock_request)
allow(component).to receive(:respond_to?).with(:request).and_return(true)

path_with_context = component.send(:switch_locale_path, 'es')
puts "Path with context: #{path_with_context}"  # Expected: "/es/complex/path"
```

---

## 🚨 **Error Scenario Testing**

### **1. Missing Translation Handling**
```ruby
# Test missing translation graceful handling
I18n.locale = :en

# Mock missing translation
allow(I18n).to receive(:t).with("nav.missing_key").and_raise(
  I18n::MissingTranslationData.new(:en, :missing_key, {})
)

# Component should handle this gracefully
component = Ui::LanguageSwitcherComponent.new
# Should not raise error when rendered

# Test fallback behavior
result = begin
  I18n.t("nav.missing_key", default: "Fallback")
rescue I18n::MissingTranslationData
  "Error handled"
end
puts "Missing translation result: #{result}"
```

### **2. Path Processing Error Handling**
```ruby
component = Ui::LanguageSwitcherComponent.new

# Mock request that will cause an error
mock_request = double(path: '/test', present?: true)
allow(component).to receive(:request).and_return(mock_request)
allow(component).to receive(:respond_to?).with(:request).and_return(true)

# Force an error in path processing
allow(mock_request).to receive(:path).and_raise(StandardError, "Path error")

# Should handle gracefully and return fallback path
result = component.send(:switch_locale_path, 'es')
puts "Error handling result: #{result}"  # Expected: "/es/" (fallback)
```

### **3. Invalid Locale Handling**
```ruby
# Test with invalid locale
component = Ui::LanguageSwitcherComponent.new

# Should handle gracefully (no error)
result = component.send(:switch_locale_path, 'invalid')
puts "Invalid locale result: #{result}"

# Test locale name for unsupported locale
name = component.send(:locale_name, :fr)
puts "Unsupported locale name: #{name}"  # Expected: "Fr" (humanized)
```

---

## 🎨 **UI/UX Testing**

### **1. Visual Component Testing**
```bash
# Test component rendering with ViewComponent test helpers
bundle exec rspec spec/components/ui/language_switcher_component_spec.rb -t "render"

# Should test:
# - Component renders without errors
# - Correct links are generated
# - Proper styling classes are applied
# - Content appears in correct language
```

### **2. Browser Compatibility Testing**
```
Test in different browsers:
1. Chrome/Chromium - language switching
2. Firefox - URL handling  
3. Safari - locale persistence
4. Mobile browsers - touch interaction

Verify:
- Language switcher is clickable
- URLs update correctly
- Page content updates appropriately
- No JavaScript errors in console
```

---

## 📊 **Performance Testing**

### **1. Locale Loading Performance**
```ruby
# Test translation loading performance
require 'benchmark'

time = Benchmark.measure do
  1000.times do
    I18n.locale = :en
    I18n.t("nav.english")
    I18n.locale = :es  
    I18n.t("nav.spanish")
  end
end

puts "Translation performance: #{time.real} seconds"
```

### **2. Component Rendering Performance**
```ruby
# Test component rendering performance  
require 'benchmark'

time = Benchmark.measure do
  100.times do
    component = Ui::LanguageSwitcherComponent.new
    # Simulate rendering (would need ActionView context in real app)
  end
end

puts "Component creation performance: #{time.real} seconds"
```

---

## 🔍 **Integration Testing**

### **1. Full Application Flow**
```
1. User Journey Test:
   - Start at homepage (/)
   - Navigate to planning (/plannings)
   - Switch to Spanish (/es/plannings)
   - Create new item (/es/plannings/new)
   - Switch back to English (/plannings/new)
   - Complete form submission
   - Verify success message in correct language

2. Session Persistence:
   - Switch to Spanish
   - Navigate away and return
   - Verify language preference is maintained
   - Test across page reloads
```

### **2. API Integration (if applicable)**
```ruby
# If API endpoints need to respect locale
# Test API responses include proper locale information

response = api_client.get('/api/v1/plannings', headers: { 'Accept-Language' => 'es' })
# Verify response includes Spanish text where applicable
```

---

## ✅ **Test Checklist**

### **Automated Tests**
- [ ] Language switcher component tests pass (96%+ coverage)
- [ ] Translation files are valid YAML
- [ ] All required translations exist in both locales
- [ ] Component handles error cases gracefully

### **Manual Tests**  
- [ ] Language switching works in browser
- [ ] URLs update correctly with locale prefixes
- [ ] Content displays in correct language
- [ ] Complex path scenarios work properly
- [ ] Browser navigation works correctly

### **Edge Cases**
- [ ] Missing translations are handled gracefully
- [ ] Invalid locales don't break the application  
- [ ] Path processing errors are handled
- [ ] Component works without request context
- [ ] Deep-linked URLs with locales work correctly

### **Integration Tests**
- [ ] Full user journey works across language switches
- [ ] Session/cookie handling preserves language preference
- [ ] Form submissions work in both languages
- [ ] Error messages appear in correct language

---

## 📝 **Common Issues and Solutions**

### **Issue 1: Language not switching**
```
Symptoms: Clicking language switcher doesn't change language
Debugging:
1. Check if locale files exist and are valid
2. Verify routing configuration
3. Check if I18n.locale is being set correctly
4. Inspect browser developer tools for JavaScript errors
```

### **Issue 2: URLs not generating correctly**
```
Symptoms: Incorrect locale prefixes in URLs
Debugging:
1. Test path generation in Rails console
2. Verify component path logic
3. Check routing configuration for locale handling
4. Test with different request contexts
```

### **Issue 3: Missing translations**
```
Symptoms: Translation keys appear instead of text
Debugging:
1. Verify translation files have correct structure
2. Check for typos in translation keys
3. Confirm fallback behavior is working
4. Test with I18n.available_locales
```

---

This testing guide ensures comprehensive validation of all internationalization features and maintains consistent multilingual user experience.