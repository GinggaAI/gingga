# Testing Guide: New Screens and Components Implementation

This document provides comprehensive testing instructions for the newly implemented screens and UI components in the Gingga Rails application.

## 🚀 Quick Start Testing

### Prerequisites
1. Start the Rails server: `bin/dev` or `rails server`
2. Ensure you have a user account and are logged in
3. Database should be migrated and seeded

### Essential Test Routes
- **My Brand**: http://localhost:3000/my-brand
- **Scene-Based Reel**: http://localhost:3000/reels/scene-based
- **Narrative Reel**: http://localhost:3000/reels/narrative
- **Smart Planning**: http://localhost:3000/smart-planning
- **Component Previews**: http://localhost:3000/rails/view_components

---

## 📋 Detailed Testing Procedures

### 1. My Brand Page (`/my-brand`)

#### Test Cases
**TC1.1: Basic Form Rendering**
1. Navigate to `/my-brand`
2. ✅ Verify page title shows "My Brand"
3. ✅ Check all form sections are visible:
   - Brand Identity
   - Audience & Offer
   - Content Preferences
4. ✅ Verify all Brand model fields are present

**TC1.2: Form Validation**
1. Submit empty form
2. ✅ Check validation errors display
3. ✅ Verify required fields are highlighted

**TC1.3: Multi-Brand Support**
1. Create a brand profile
2. ✅ Verify brand switcher appears after saving
3. Click "Add New Brand"
4. ✅ Confirm new brand form loads
5. Switch between brands using dropdown
6. ✅ Verify correct brand data loads

**TC1.4: Success Flow**
1. Fill out complete brand form
2. Submit form
3. ✅ Verify success toast appears
4. ✅ Check data persists on page reload

### 2. Scene-Based Reel Creation (`/reels/scene-based`)

#### Test Cases
**TC2.1: Dynamic Scene Management**
1. Navigate to `/reels/scene-based`
2. ✅ Verify 3 default scenes render
3. ✅ Check scene counter shows "3 scenes"
4. Click "Add Scene"
5. ✅ Verify new scene appears and counter updates
6. ✅ Verify remove buttons work (except scene 1)

**TC2.2: Character Counter**
1. Type in any script textarea
2. ✅ Verify character counter updates in real-time
3. ✅ Check counter changes color near limits
4. Type over 500 characters
5. ✅ Verify form validation prevents submission

**TC2.3: AI Avatar Toggle**
1. ✅ Verify toggle renders and functions
2. Toggle on/off
3. ✅ Check state persists during form interaction

**TC2.4: Form Submission**
1. Fill required fields for all scenes
2. Submit form
3. ✅ Verify success redirect with toast
4. Submit incomplete form
5. ✅ Check validation errors display

### 3. Narrative Reel Creation (`/reels/narrative`)

#### Test Cases
**TC3.1: Dynamic Category/Format Loading**
1. Navigate to `/reels/narrative`
2. ✅ Verify category and format dropdowns populate
3. Open browser dev tools → Network tab
4. Refresh page
5. ✅ Check API calls to `/api/v1/categories` and `/api/v1/formats`

**TC3.2: Form Completion**
1. Fill all required fields
2. ✅ Verify story content textarea accepts long text
3. Submit form
4. ✅ Check success flow works

**TC3.3: Navigation Between Creation Methods**
1. Click "Scene-Based" tab
2. ✅ Verify navigation to scene-based page
3. Click "Narrative" tab
4. ✅ Verify navigation back to narrative page

### 4. Smart Planning Page (`/smart-planning`)

#### Test Cases
**TC4.1: Responsive Grid Layout**
1. Navigate to `/smart-planning`
2. ✅ Verify 4-column grid on desktop
3. Resize browser to mobile width
4. ✅ Check layout switches to 1 column

**TC4.2: Planning Cards**
1. ✅ Verify 4 sample planning cards render
2. ✅ Check each card shows:
   - Week number
   - Date range
   - Content count
   - Goal badges
   - Status-appropriate action button
3. ✅ Verify different statuses display correctly

**TC4.3: Goal Badges and Chips**
1. ✅ Verify goal badges use different colors
2. ✅ Check content type chips render correctly
3. ✅ Verify feature explanation cards at bottom

---

## 🧩 Component Testing (ViewComponent Previews)

### Accessing Component Previews
1. Navigate to http://localhost:3000/rails/view_components
2. Test each component in isolation

### Component Test Checklist

#### Button Component
- ✅ Primary, ghost, gradient variants
- ✅ Different sizes (sm, md, lg)
- ✅ Disabled state
- ✅ Link functionality

#### Form Section Component
- ✅ With and without description
- ✅ Content slot functionality
- ✅ Proper semantic structure

#### Toggle Component
- ✅ Checked/unchecked states
- ✅ Disabled state
- ✅ Accessibility (ARIA labels)
- ✅ Description text

#### Badge Component
- ✅ All variants (primary, secondary, goal types)
- ✅ Different sizes
- ✅ Goal-specific styling

#### Chip Component
- ✅ All variants
- ✅ Removable chips
- ✅ Link functionality
- ✅ Content type examples

#### Toast Component
- ✅ All variants (success, warning, error, info)
- ✅ Dismissible/non-dismissible
- ✅ Auto-dismiss functionality
- ✅ Proper icons

#### Planning Week Card Component
- ✅ Different statuses (draft, scheduled, published)
- ✅ Multiple goals display
- ✅ Date formatting
- ✅ Action buttons per status

#### Scene Fields Component
- ✅ Default state
- ✅ With pre-filled data
- ✅ Remove button (scenes > 1)
- ✅ Form field rendering

---

## 🧪 Automated Testing

### Running Component Tests
```bash
# Run all component tests
bundle exec rspec spec/components/

# Run specific component test
bundle exec rspec spec/components/ui/button_component_spec.rb

# Run with documentation format
bundle exec rspec spec/components/ --format documentation
```

### Running Controller Tests
```bash
# Run new controller tests
bundle exec rspec spec/controllers/reels_controller_spec.rb
bundle exec rspec spec/controllers/api/v1/

# Run all tests
bundle exec rspec
```

### Code Quality Checks
```bash
# Run RuboCop linting
bundle exec rubocop app/components/ui/ app/controllers/reels_controller.rb

# Auto-correct issues
bundle exec rubocop --autocorrect

# Check specific files
bundle exec rubocop app/views/reels/
```

---

## 🎯 Manual Testing Scenarios

### End-to-End User Flows

#### Scenario 1: Brand Setup → Reel Creation
1. **Setup Brand**
   - Navigate to `/my-brand`
   - Fill complete brand profile
   - Save successfully

2. **Create Scene-Based Reel**
   - Go to `/reels/scene-based`
   - Add 2 additional scenes (5 total)
   - Fill all scene details
   - Enable AI Avatar
   - Submit successfully

3. **Create Narrative Reel**
   - Go to `/reels/narrative`
   - Select category and format
   - Write story content
   - Submit successfully

#### Scenario 2: Planning Workflow
1. **View Smart Planning**
   - Navigate to `/smart-planning`
   - Review generated weekly plans
   - Click action buttons
   - Verify responsive behavior

2. **Multi-Brand Management**
   - Create second brand profile
   - Switch between brands
   - Verify data isolation

---

## 🚨 Error Testing

### Testing Error Conditions
1. **Network Failures**
   - Disable network in dev tools
   - Try narrative form (categories/formats won't load)
   - ✅ Verify graceful degradation

2. **Validation Errors**
   - Submit forms with missing required fields
   - ✅ Check error messages display
   - ✅ Verify form state preservation

3. **JavaScript Disabled**
   - Disable JavaScript in browser
   - ✅ Verify forms still function (progressive enhancement)

---

## 📱 Accessibility Testing

### Manual Accessibility Checks
1. **Keyboard Navigation**
   - Tab through all interactive elements
   - ✅ Verify focus indicators visible
   - ✅ Check logical tab order

2. **Screen Reader Testing**
   - Use screen reader to navigate forms
   - ✅ Verify ARIA labels read correctly
   - ✅ Check form field associations

3. **Color Contrast**
   - ✅ Verify all text meets WCAG 2.1 AA standards
   - ✅ Check focus states are visible

### Automated Accessibility Testing
```bash
# If pa11y is available
pa11y http://localhost:3000/my-brand
pa11y http://localhost:3000/reels/scene-based
pa11y http://localhost:3000/smart-planning
```

---

## 🔧 Troubleshooting

### Common Issues and Solutions

#### Components Not Rendering
```bash
# Check ViewComponent is properly configured
rails c
ViewComponent::Base.preview_paths
```

#### Stimulus Controllers Not Working
1. Check browser console for JavaScript errors
2. Verify controller files are in `app/javascript/controllers/`
3. Ensure controller names match data-controller attributes

#### API Endpoints Not Responding
```bash
# Test API endpoints directly
curl http://localhost:3000/api/v1/categories
curl http://localhost:3000/api/v1/formats
```

#### Styling Issues
1. Verify CSS variables are defined in `tokens.css`
2. Check Tailwind classes compile correctly
3. Run `npm run build:css` if styles are missing

---

## 📊 Test Coverage

### Expected Test Results
- **Component Tests**: 22+ examples, 0 failures
- **Controller Tests**: All new controllers covered
- **Integration Tests**: Key user flows tested

### Coverage Goals
- **UI Components**: 100% coverage for public interfaces
- **Controllers**: >90% coverage for new actions
- **JavaScript**: Manual testing of Stimulus interactions

---

## 📝 Test Reporting

### When Tests Fail
1. **Document the Issue**
   - Screenshot of error
   - Browser/device information
   - Steps to reproduce

2. **Check Recent Changes**
   - Review recent commits
   - Verify dependencies are up to date

3. **Environment Issues**
   - Clear browser cache
   - Restart Rails server
   - Check database state

### Success Criteria
✅ All automated tests pass  
✅ Manual testing scenarios complete successfully  
✅ Components render correctly in previews  
✅ Forms submit and validate properly  
✅ Responsive design works across devices  
✅ Accessibility requirements met  
✅ No JavaScript console errors  

---

## 🎉 Final Validation

Before marking implementation complete:

1. ✅ Run full test suite: `bundle exec rspec`
2. ✅ Check component previews: `/rails/view_components`
3. ✅ Test each main route manually
4. ✅ Verify responsive design on mobile/desktop
5. ✅ Confirm accessibility standards met
6. ✅ Check JavaScript functionality works
7. ✅ Validate form submissions and error handling

**Implementation is complete when all checkboxes are verified!** ✨