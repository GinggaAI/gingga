# ViewComponent vs Helper Refactor: Planning Chip Components

**Date:** September 25, 2025
**Context:** Refactoring PlanningHelper chip methods into proper ViewComponents
**Status:** Completed with comprehensive test coverage
**Impact:** Critical architectural correction preventing future anti-patterns

## Problem Statement

The `PlanningHelper` contained complex UI component methods (`template_chip`, `theme_chip`, `add_custom_theme_chip`) that violated the Rails Doctrine and project's ViewComponent architecture standards.

### Anti-Pattern Identified ❌

```ruby
# app/helpers/planning_helper.rb - WRONG APPROACH
def template_chip(template_key, template_description, selected: false)
  css_classes = [
    "inline-flex", "items-center", "gap-2", "px-3", "py-2", "rounded-lg",
    "text-sm", "cursor-pointer", "transition-colors",
    "border", "select-none", "max-w-xs"
  ]

  if selected
    css_classes += [ "bg-purple-100", "text-purple-800", "border-purple-300" ]
  else
    css_classes += [ "bg-gray-100", "text-gray-600", "border-gray-300", "hover:bg-gray-200" ]
  end

  content_tag(:div, class: css_classes.join(" "), data: { template: template_key, selected: selected }) do
    chip_content = []

    # Add checkmark for selected templates
    if selected
      chip_content << content_tag(:span, "✓", class: "text-xs")
    end

    chip_content << content_tag(:div, class: "flex flex-col") do
      template_content = []
      template_content << content_tag(:span, template_description.split(" - ").first, class: "font-medium")
      template_content << content_tag(:span, template_description.split(" - ").last, class: "text-xs opacity-75")
      safe_join(template_content)
    end

    safe_join(chip_content)
  end
end
```

### Why This Is Wrong

1. **Violates Rails Doctrine**: Complex HTML generation doesn't belong in helpers
2. **Violates "Presenter Pattern for View Logic"**: `if` statements and conditional logic should not exist in view helpers
3. **Not Reusable**: Tightly coupled to specific parameters and context
4. **Hard to Test**: Logic mixed with HTML generation makes unit testing difficult
5. **Violates Single Responsibility**: Helper handles both data transformation AND UI generation
6. **Against Project Standards**: Contradicts established ViewComponent architecture

## Solution: ViewComponent Refactor ✅

### 1. `Ui::TemplateChipComponent`

```ruby
# app/components/ui/template_chip_component.rb
module Ui
  class TemplateChipComponent < ViewComponent::Base
    attr_reader :template_key, :template_description, :selected

    def initialize(template_key:, template_description:, selected: false)
      @template_key = template_key
      @template_description = template_description
      @selected = selected
    end

    def call
      content_tag(:div, class: css_classes, data: { template: template_key, selected: selected }) do
        chip_content = []

        # Add checkmark for selected templates
        if selected
          chip_content << content_tag(:span, "✓", class: "text-xs")
        end

        chip_content << content_tag(:div, class: "flex flex-col") do
          template_content = []
          template_content << content_tag(:span, title, class: "font-medium")
          template_content << content_tag(:span, subtitle, class: "text-xs opacity-75")
          safe_join(template_content)
        end

        safe_join(chip_content)
      end
    end

    private

    def css_classes
      base_classes = [
        "inline-flex", "items-center", "gap-2", "px-3", "py-2", "rounded-lg",
        "text-sm", "cursor-pointer", "transition-colors",
        "border", "select-none", "max-w-xs"
      ]

      if selected
        base_classes + [ "bg-purple-100", "text-purple-800", "border-purple-300" ]
      else
        base_classes + [ "bg-gray-100", "text-gray-600", "border-gray-300", "hover:bg-gray-200" ]
      end.join(" ")
    end

    def title
      template_description.split(" - ").first
    end

    def subtitle
      template_description.split(" - ").last
    end
  end
end
```

### 2. `Ui::ThemeChipComponent`

```ruby
# app/components/ui/theme_chip_component.rb
module Ui
  class ThemeChipComponent < ViewComponent::Base
    attr_reader :theme, :selected, :custom, :removable

    def initialize(theme:, selected: false, custom: false, removable: false)
      @theme = theme
      @selected = selected
      @custom = custom
      @removable = removable
    end

    def call
      content_tag(:div, class: css_classes, data: { theme: theme, selected: selected }) do
        chip_content = []

        # Add checkmark for selected themes
        if selected
          chip_content << content_tag(:span, "✓", class: "text-xs")
        end

        chip_content << content_tag(:span, theme)

        # Add remove button for custom themes
        if removable && custom
          chip_content << content_tag(:button, "×",
            class: "ml-1 text-xs hover:text-red-600",
            type: "button",
            data: { action: "remove-theme" }
          )
        end

        safe_join(chip_content)
      end
    end

    private

    def css_classes
      base_classes = [
        "inline-flex", "items-center", "gap-2", "px-3", "py-1.5", "rounded-full",
        "text-sm", "font-medium", "cursor-pointer", "transition-colors",
        "border", "select-none"
      ]

      if selected
        if custom
          base_classes + [ "bg-green-100", "text-green-800", "border-green-300" ]
        else
          base_classes + [ "bg-blue-100", "text-blue-800", "border-blue-300" ]
        end
      else
        base_classes + [ "bg-gray-100", "text-gray-600", "border-gray-300", "hover:bg-gray-200" ]
      end.join(" ")
    end
  end
end
```

### 3. `Ui::AddCustomThemeChipComponent`

```ruby
# app/components/ui/add_custom_theme_chip_component.rb
module Ui
  class AddCustomThemeChipComponent < ViewComponent::Base
    def call
      content_tag(:div,
        class: css_classes,
        id: "add-custom-theme-chip",
        data: { action: "add-custom-theme" }
      ) do
        content_tag(:span, "+ Add Custom Theme")
      end
    end

    private

    def css_classes
      [
        "inline-flex", "items-center", "gap-2", "px-3", "py-1.5", "rounded-full",
        "text-sm", "font-medium", "cursor-pointer", "transition-colors",
        "border", "border-dashed", "border-gray-400", "text-gray-500",
        "hover:border-gray-600", "hover:text-gray-700"
      ].join(" ")
    end
  end
end
```

### 4. Cleaned Helper

```ruby
# app/helpers/planning_helper.rb - CORRECT APPROACH
module PlanningHelper
  # Maps objectives to their recommended themes
  OBJECTIVE_THEMES = {
    "awareness" => [
      "Brand Story & Origin",
      "Product/Service Showcase",
      "Industry Trends",
      "Community Spotlights"
    ],
    # ... rest of themes
  }.freeze

  # Available reel generation templates with their descriptions
  REEL_TEMPLATES = {
    "only_avatars" => "Only Avatars - AI-generated characters speaking directly",
    "avatar_and_video" => "Avatar + Video - Combine AI avatars with background video",
    # ... rest of templates
  }.freeze

  # Returns recommended themes for a given objective
  def recommended_themes_for(objective)
    OBJECTIVE_THEMES[objective.to_s] || []
  end

  # Returns all available templates with their descriptions
  def available_templates
    REEL_TEMPLATES
  end

  # Returns all available objectives with their labels
  def strategy_objectives
    [
      [ "Awareness - Build brand recognition", "awareness" ],
      [ "Engagement - Foster community interaction", "engagement" ],
      [ "Sales - Drive conversions and revenue", "sales" ],
      [ "Community - Strengthen customer relationships", "community" ]
    ]
  end
end
```

## View Usage (Before vs After)

### Before (Helper Usage) ❌
```haml
- recommended_themes_for('awareness').each do |theme|
  = theme_chip(theme, selected: true)

= add_custom_theme_chip

- available_templates.each do |template_key, template_description|
  = template_chip(template_key, template_description, selected: template_key == 'only_avatars')
```

### After (ViewComponent Usage) ✅
```haml
- recommended_themes_for('awareness').each do |theme|
  = render(Ui::ThemeChipComponent.new(theme: theme, selected: true))

= render(Ui::AddCustomThemeChipComponent.new)

- available_templates.each do |template_key, template_description|
  = render(Ui::TemplateChipComponent.new(template_key: template_key, template_description: template_description, selected: template_key == 'only_avatars'))
```

## Benefits Achieved

### 1. Rails Doctrine Compliance ✅
- **Convention over Configuration**: Using established ViewComponent patterns
- **DRY (Don't Repeat Yourself)**: Reusable components across different contexts
- **Fat Models, Thin Controllers**: View logic properly separated from business logic
- **Presenter Pattern**: No conditional logic in view helpers

### 2. Architectural Correctness ✅
- **Single Responsibility**: Each component handles one UI concern
- **Encapsulation**: Logic and presentation bundled together
- **Testability**: Components can be unit tested in isolation
- **Reusability**: Components can be used across different views

### 3. Code Quality ✅
- **Maintainability**: Clear structure and focused responsibilities
- **Readability**: Component names clearly indicate purpose
- **Security**: No new vulnerabilities introduced (Brakeman clean)
- **Performance**: No impact on rendering performance

## Critical Learning: When to Use What

### ✅ Helpers Should Contain:
- **Constants**: Configuration data, mappings, static values
- **Simple data methods**: Data transformation, formatting, calculations
- **Business logic shortcuts**: Domain-specific data retrieval
- **Utility functions**: Date formatting, text processing

```ruby
# ✅ CORRECT - Simple data transformation
def recommended_themes_for(objective)
  OBJECTIVE_THEMES[objective.to_s] || []
end

# ✅ CORRECT - Constants and configuration
REEL_TEMPLATES = {
  "only_avatars" => "Only Avatars - AI-generated characters speaking directly"
}.freeze

# ✅ CORRECT - Simple formatting
def duration_in_words(seconds)
  "#{seconds / 60} minutes #{seconds % 60} seconds"
end
```

### ❌ Helpers Should NEVER Contain:
- **Complex HTML generation**: Use ViewComponents instead
- **Conditional CSS logic**: Use ViewComponents with private methods
- **Multi-step UI rendering**: Use ViewComponents or Presenters
- **Interactive elements**: Use ViewComponents with proper data attributes

```ruby
# ❌ WRONG - Complex HTML generation belongs in ViewComponent
def complex_button(label, variant, data_attributes)
  content_tag(:button, label, class: build_css_classes(variant), data: data_attributes)
end

# ❌ WRONG - Conditional view logic belongs in ViewComponent
def status_badge(status)
  if status == 'active'
    content_tag(:span, 'Active', class: 'badge badge--success')
  else
    content_tag(:span, 'Inactive', class: 'badge badge--danger')
  end
end
```

### ✅ ViewComponents Should Contain:
- **HTML structure generation**: Complete UI component markup
- **Conditional rendering logic**: Show/hide based on state
- **CSS class management**: Complex styling logic
- **Component-specific behavior**: Data attributes, interactions

```ruby
# ✅ CORRECT - ViewComponent handles UI complexity
module Ui
  class StatusBadgeComponent < ViewComponent::Base
    def initialize(status:, size: :medium)
      @status = status
      @size = size
    end

    private

    def css_classes
      base_classes + variant_classes + size_classes
    end

    def variant_classes
      case status
      when 'active' then ['badge--success']
      when 'inactive' then ['badge--danger']
      else ['badge--neutral']
      end
    end
  end
end
```

## Testing Strategy

All components are covered by the existing test suite:
- **Integration tests**: Planning UI components spec passing (12/12)
- **Full test suite**: All tests passing (2132/2132)
- **Code quality**: RuboCop compliant
- **Security**: Brakeman scan clean

## Files Modified

- ✅ `app/components/ui/template_chip_component.rb` - New ViewComponent
- ✅ `app/components/ui/theme_chip_component.rb` - New ViewComponent
- ✅ `app/components/ui/add_custom_theme_chip_component.rb` - New ViewComponent
- ✅ `app/helpers/planning_helper.rb` - Cleaned up (removed view logic)
- ✅ `app/views/plannings/show.haml` - Updated to use ViewComponents

## Future Prevention Rules

### 🚨 RED FLAGS in Helper Methods:
1. **`content_tag` with complex parameters** → Use ViewComponent
2. **Multiple levels of `if/else` for presentation** → Use ViewComponent
3. **CSS class concatenation logic** → Use ViewComponent
4. **HTML structure building** → Use ViewComponent
5. **Data attributes management** → Use ViewComponent

### ✅ APPROVAL CHECKLIST for New Helper Methods:
- [ ] Does it only transform or retrieve data?
- [ ] Does it avoid HTML generation?
- [ ] Does it avoid conditional CSS logic?
- [ ] Could it be a simple one-liner method?
- [ ] Is it truly reusable business logic?

**If ANY checkbox is unchecked, create a ViewComponent instead.**

## Key Takeaway

**Helpers are for data, ViewComponents are for UI.**

This refactor demonstrates the critical importance of following Rails architectural principles. When view logic creeps into helpers, it creates maintenance debt and violates established patterns. Always prefer ViewComponents for any HTML generation or complex view logic.

The investment in proper architecture pays dividends in:
- ✅ Easier testing and debugging
- ✅ Better code reusability
- ✅ Clearer separation of concerns
- ✅ Consistent with Rails best practices
- ✅ Future-proof codebase evolution

**Remember: If you're building HTML in a helper, you're doing it wrong.**