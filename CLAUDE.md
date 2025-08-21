# CLAUDE.md - Gingga Rails Application Contributor Guide

## 📋 Getting Started

**READ THIS FIRST**: This document is the main contributor guide for the Gingga Rails application. Before writing any code, read this document completely and review the relevant documentation in the `/doc` folder.

---

## 📁 Documentation Structure

All documentation is organized in `/doc` with the following structure:

- **`/doc/backend/`** - Backend architecture, API, database, models, services, and integrations
- **`/doc/frontend/`** - Frontend UI structure, components, JavaScript logic, and styling
- **`/doc/manual_test/`** - Manual testing guides for QA and user-facing testing

**IMPORTANT**: Always check the relevant `/doc` subdirectory for context before starting work on any feature or bug fix.

---

## 🏗️ Development Standards

We follow strict development standards to ensure high-quality, maintainable code:

### Core Principles
- **Ruby on Rails conventions** - Follow Rails best practices and idioms
- **Rails Doctrine** - Follow the Rails way: Convention over Configuration, DRY, Fat Models/Thin Controllers
- **POST-REDIRECT-GET Pattern** - **IMPORTANT**: Always implement POST-REDIRECT-GET pattern for forms to prevent duplicate submissions and improve user experience
- **Test-Driven Development (TDD)** - Write tests first, then implement
- **90%+ test coverage** - All new files must achieve at least 90% test coverage
- **Service-oriented architecture** - Extract business logic into service objects
- **Security-first mindset** - Always consider security implications

### Rails Doctrine and Patterns

#### POST-REDIRECT-GET Pattern (PRG)
**CRITICAL REQUIREMENT**: All form submissions MUST follow the POST-REDIRECT-GET pattern:

```ruby
# ✅ CORRECT - POST-REDIRECT-GET Pattern
def create
  @resource = Resource.new(resource_params)
  
  if @resource.save
    redirect_to @resource, notice: 'Resource was successfully created.'
  else
    render :new, status: :unprocessable_content
  end
end

# ❌ INCORRECT - Direct template rendering without redirect
def create
  @resource = Resource.new(resource_params)
  @resource.save
  render :show  # This violates PRG pattern
end
```

**Why PRG is Essential:**
- Prevents duplicate form submissions on browser refresh
- Improves user experience and data integrity
- Follows Rails conventions and web standards
- Enables proper browser history navigation

#### Rails Doctrine Adherence
Follow these fundamental Rails principles:

1. **Convention over Configuration**
   - Use Rails naming conventions for models, controllers, views
   - Follow RESTful routing patterns
   - Use standard Rails directory structure

2. **DRY (Don't Repeat Yourself)**
   - Extract common code into helpers, concerns, or services
   - Use partials for repeated view logic
   - Leverage Rails generators and conventions

3. **Fat Models, Thin Controllers**
   - Business logic belongs in models or service objects
   - Controllers should orchestrate, not implement business rules
   - Keep controller actions focused on HTTP concerns

4. **Presenter Pattern for View Logic**
   - **FORBIDDEN**: No `if` statements in views - this indicates need for a presenter
   - Extract all conditional logic from views into presenter objects
   - Views should only contain display logic and simple iteration
   - Use presenters to encapsulate complex view logic and formatting

### Required Quality Gates
- ✅ All tests must pass (`bundle exec rspec`)
- ✅ 90%+ code coverage on new/modified files
- ✅ No RuboCop violations
- ✅ No security issues (Brakeman scan)
- ✅ All deprecation warnings resolved
- ✅ POST-REDIRECT-GET pattern implemented for all forms
- ✅ Rails Doctrine principles followed

---

## 📝 Contribution Documentation Process

**PROACTIVE DOCUMENTATION**: For every contribution, you must document:

### 1. What Was Developed
- Clear description of the feature/fix
- Architecture decisions made
- New files/classes/methods created
- Database changes (migrations, models)

### 2. Problems or Bugs That Appeared
- Issues encountered during development
- Error messages and their root causes
- Failed approaches and why they didn't work
- Performance or compatibility issues

### 3. How They Were Resolved
- Step-by-step solution process
- Code changes made with before/after examples
- Testing strategies used
- Verification methods applied

### 4. What Should Be Avoided in Future
- Anti-patterns identified
- Common pitfalls for future developers
- Configuration issues to watch for
- Technical debt introduced (if any)

### Documentation Location
- **Backend contributions**: Add to relevant file in `/doc/backend/`
- **Frontend contributions**: Add to relevant file in `/doc/frontend/`
- **Complex fixes**: Create new document following naming pattern: `<feature>_implementation_<date>.md`

---

## 🏗️ Project Architecture

### Backend Structure
```
app/
├── controllers/           # HTTP request handling
├── models/               # Data models and business rules
├── services/             # Business logic extraction
│   ├── domain_name/
│   │   └── action_service.rb
├── presenters/           # View logic encapsulation
├── serializers/          # API response formatting
├── jobs/                 # Background processing
└── policies/             # Authorization logic

spec/                     # Test files mirroring app/ structure
├── services/
├── models/
├── controllers/
├── integration/
└── support/
    └── factories/
```

### Frontend Architecture
- **Server-rendered HTML** with Rails views
- **Hotwire** (Turbo + Stimulus) for enhanced interactivity
- **ViewComponent** for reusable UI components
- **Tailwind CSS** for styling with design tokens
- **React islands** only when explicitly approved

---

## 🧪 Testing Standards

### Test Coverage Requirements
- **New files**: Minimum 90% line coverage
- **Modified files**: Maintain or improve existing coverage
- **Critical paths**: 100% coverage for authentication, payments, data integrity

### Testing Structure
```
spec/
├── models/              # Model validations, associations, business logic
├── services/            # Service object functionality and edge cases
├── controllers/         # HTTP responses, authentication, authorization
├── integration/         # Full workflow testing
├── system/              # End-to-end browser testing
└── factories/           # Test data creation
```

### Testing Best Practices
- **Test-first approach**: Write failing tests before implementation
- **Descriptive test names**: Clearly describe what is being tested
- **Arrange-Act-Assert**: Structure tests for clarity
- **Mock external dependencies**: Use stubs/mocks for API calls, file systems
- **Test edge cases**: Handle nil values, empty arrays, validation failures

### Example Test Structure
```ruby
RSpec.describe SomeService do
  describe '#call' do
    context 'when valid parameters are provided' do
      it 'creates the expected result' do
        # Arrange
        user = create(:user)
        params = { name: 'Test' }
        
        # Act
        result = described_class.new(user: user, params: params).call
        
        # Assert  
        expect(result.success?).to be true
        expect(result.data[:name]).to eq('Test')
      end
    end
    
    context 'when invalid parameters are provided' do
      it 'returns an error result' do
        # Test error conditions
      end
    end
  end
end
```

---

## 🔧 Service Object Pattern

Extract complex business logic into service objects following this pattern:

### Service Object Structure
```ruby
# app/services/domain/action_service.rb
module Domain
  class ActionService
    def initialize(user:, **options)
      @user = user
      @options = options
    end

    def call
      return failure_result('User required') unless @user
      
      # Business logic here
      
      success_result(data: processed_data)
    rescue StandardError => e
      failure_result("Error: #{e.message}")
    end

    private

    def processed_data
      # Implementation details
    end

    def success_result(data:)
      OpenStruct.new(success?: true, data: data, error: nil)
    end

    def failure_result(error_message)
      OpenStruct.new(success?: false, data: nil, error: error_message)
    end
  end
end
```

### Service Object Guidelines
- **Single responsibility**: Each service does one thing well
- **Dependency injection**: Accept dependencies as parameters
- **Consistent interface**: Use `#call` method as entry point
- **Error handling**: Always handle and communicate errors clearly
- **Return objects**: Use consistent result objects for success/failure

---

## 🎨 Frontend Standards

### CSS Architecture
- **Design tokens**: Use CSS variables defined in `app/assets/stylesheets/tokens.css`
- **Tailwind CSS**: For utility-based styling
- **Component-specific CSS**: Co-located with ViewComponents when needed
- **Build process**: `npm run build:css` compiles to `app/assets/builds/application.css`

### ViewComponent Guidelines  
```ruby
# app/components/ui/button_component.rb
class UI::ButtonComponent < ViewComponent::Base
  def initialize(variant: :primary, size: :medium, **options)
    @variant = variant
    @size = size
    @options = options
  end

  private

  attr_reader :variant, :size, :options
end
```

### JavaScript (Stimulus Controllers)
```javascript
// app/javascript/controllers/example_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["output"]
  static values = { count: Number }

  connect() {
    // Initialization logic
  }

  increment() {
    this.countValue++
    this.outputTarget.textContent = this.countValue
  }
}
```

---

## 🔒 Security Best Practices

### Always Consider
- **Input validation**: Validate all user inputs
- **SQL injection prevention**: Use parameterized queries
- **XSS protection**: Sanitize output in views
- **Authentication**: Verify user permissions
- **API security**: Validate API tokens and rate limiting
- **Secrets management**: Never commit secrets to repository

### Security Checklist
- [ ] All user inputs validated
- [ ] Sensitive data encrypted at rest
- [ ] API endpoints properly authenticated
- [ ] No secrets in code or logs
- [ ] Error messages don't leak sensitive information

---

## 🚀 Development Workflow

### 1. Planning Phase
1. **Read documentation**: Review relevant `/doc` files for context
2. **Understand requirements**: Clarify acceptance criteria
3. **Design approach**: Plan architecture and identify dependencies
4. **Write tests first**: Define expected behavior with failing tests

### 2. Implementation Phase
1. **Create feature branch**: `feature/<ticket-id>-<description>`
2. **Write failing tests**: Red phase of TDD
3. **Implement minimum code**: Green phase of TDD  
4. **Refactor**: Clean up code while keeping tests green
5. **Add documentation**: Update relevant `/doc` files

### 3. Quality Assurance
1. **Run full test suite**: `bundle exec rspec`
2. **Check coverage**: Ensure 90%+ on new/modified files
3. **Lint code**: `bundle exec rubocop --auto-correct`
4. **Security scan**: `bundle exec brakeman`
5. **Manual testing**: Verify feature works as expected

### 4. Contribution Documentation
Create/update documentation in appropriate `/doc` subdirectory with:
- What was developed and why
- Problems encountered and solutions
- Lessons learned for future development
- Any technical debt or limitations introduced

---

## 📋 Development Setup

### Initial Setup
```bash
# Clone and setup
git clone <repository-url>
cd gingga
bundle install
npm install

# Database setup
rails db:create
rails db:migrate
rails db:seed

# Environment setup
cp .env.example .env
# Edit .env with your configuration

# Verify setup
bundle exec rspec
npm run build:css
```

### Daily Development
```bash
# Start development environment
bin/dev  # Runs Rails server + CSS watcher

# Or run separately:
rails server        # Rails app
npm run build:css -- --watch  # CSS compilation
```

### Before Each Commit
```bash
# Run quality checks
bundle exec rspec              # All tests
bundle exec rubocop           # Code style
bundle exec brakeman          # Security scan
npm run build:css             # Rebuild CSS
```

---

## 📋 Quality Checklists

### Code Review Checklist
- [ ] Tests pass and cover new/modified code (90%+)
- [ ] Code follows Rails conventions and Rails Doctrine
- [ ] **POST-REDIRECT-GET pattern implemented for all form submissions**
- [ ] **Rails principles followed: Convention over Configuration, DRY, Fat Models/Thin Controllers**
- [ ] Service objects used for complex business logic
- [ ] Security considerations addressed
- [ ] Error handling implemented
- [ ] Documentation updated in appropriate `/doc` subdirectory
- [ ] No hardcoded secrets or credentials
- [ ] Performance implications considered

### Bug Fix Checklist
- [ ] Root cause identified and documented
- [ ] Test written to reproduce the bug
- [ ] Fix implemented with minimal changes
- [ ] Regression tests added
- [ ] Documentation updated with problem and solution
- [ ] Similar code reviewed for same issue

---

## 🔄 Living Document Process

**This document is living and must be updated as the project evolves.**

### When to Update CLAUDE.md
- New development patterns emerge
- Significant architectural decisions are made
- Development tooling changes
- Common issues or best practices are identified
- Team processes evolve

### How to Update
1. Make changes to this file
2. Update relevant `/doc` files
3. Communicate changes to team
4. Ensure new contributors review updated version

---

## 🆘 Common Issues and Solutions

### Test Failures
- **Check test environment**: Database clean, factory definitions current
- **Review test output**: Look for specific error messages and stack traces
- **Check test coverage**: Use `open coverage/index.html` to see gaps
- **Mock external services**: Ensure API calls and external dependencies are stubbed

### CSS Not Loading
- **Rebuild CSS**: `npm run build:css`
- **Check build output**: Verify `app/assets/builds/application.css` exists
- **Restart server**: Changes may require server restart
- **Review manifest**: Check `app/assets/config/manifest.js` includes builds

### Service Integration Issues
- **Check API credentials**: Verify environment variables are set
- **Review service documentation**: Check `/doc/backend/` for service-specific guides
- **Test in isolation**: Create focused tests for service objects
- **Monitor logs**: Check `log/development.log` for detailed error information

---

## 📞 Getting Help

### Documentation Resources
1. **This guide**: Comprehensive development standards and practices
2. **`/doc/backend/`**: Backend architecture, services, and integrations  
3. **`/doc/frontend/`**: UI components, styling, and JavaScript
4. **`/doc/manual_test/`**: Testing procedures and quality assurance

### When Stuck
1. Review relevant documentation in `/doc`
2. Check test output and logs for specific errors
3. Look for similar implementations in the codebase
4. Ask team members with context documented in `/doc`

---

## ✅ Success Metrics

A successful contribution includes:
- ✅ **Functionality**: Feature works as specified
- ✅ **Testing**: 90%+ coverage with meaningful tests  
- ✅ **Quality**: Clean, readable, maintainable code
- ✅ **Security**: No vulnerabilities introduced
- ✅ **Documentation**: Clear documentation of changes and learnings
- ✅ **Performance**: No significant performance regressions

---

**Remember**: Quality over speed. It's better to deliver a well-tested, documented, and maintainable feature than to rush and introduce technical debt or bugs.

**Last Updated**: August 19, 2025  
**Version**: 2.0