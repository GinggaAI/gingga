# Contributing to Gingga Rails Application

## Overview
This document establishes unified standards for contributing to our Ruby on Rails codebase. It's optimized for service-oriented architectures with strong emphasis on test coverage, code clarity, and automated quality gates.

---

## 📘 Review Historical Context Before Starting

**IMPORTANT**: Before contributing new features or making architectural decisions:

- Navigate to the `/doc` folder
- Read the `.md` files related to previous implementations (e.g., `heygen_integration.md`)
- Review known issues, fixes, and quirks in files like:
  - `doc/heygen_integration.md`
  - `doc/heygen_integration_issue_fixes.md`

Understanding past decisions, edge cases, and bug history will help avoid regressions and duplicate work. It also ensures consistent design patterns and API usage across the project.

---

## Project Structure
```
app/
  controllers/
  models/
  services/
    domain_name/
      action_name_service.rb
  policies/
  serializers/
  jobs/
  mailers/
  views/
  helpers/
  forms/
  presenters/
lib/
  tasks/
  middleware/
spec/
  services/
  controllers/
  models/
  support/
    factories/
config/
  initializers/
  locales/
  environments/
```

---

## Frontend (Rails + Hotwire + Tailwind)

We use Rails-rendered HTML with Hotwire (Turbo + Stimulus) and Tailwind CSS for styling.

### CSS Architecture
- **Main entry**: `app/assets/stylesheets/application.tailwind.css`
- **Build output**: `app/assets/builds/application.css` (generated)
- **Build command**: `npm run build:css`
- **Development**: Use `bin/dev` or `npm run build:css -- --watch`

### Key Files
- `app/assets/manifest.js` - Links to builds and stylesheets
- `app/views/layouts/application.html.haml` - Main layout with `stylesheet_link_tag "application"`

For detailed frontend guidelines, see: `doc/frontend.md`

---

## Service-Oriented Architecture

Group domain logic into `app/services/<domain>/<action>_service.rb`

Services should:
- Follow Single Responsibility Principle
- Be testable in isolation
- Avoid side effects unless clearly documented

### Template
```ruby
# app/services/invoicing/generate_invoice_service.rb
module Invoicing
  class GenerateInvoiceService
    def initialize(user:, params:)
      @user = user
      @params = params
    end

    def call
      # ...logic here...
    end
  end
end
```

---

## Testing Standards

- **Framework**: RSpec + FactoryBot + Shoulda Matchers
- **Folder Mirroring**: `spec/` mirrors `app/` structure
- **Test Type Separation**: `spec/services`, `spec/models`, etc.
- **Factories**: defined under `spec/support/factories/`
- **Coverage Goal**: High coverage on service, model, and controller logic

### Naming
- Describe use cases: `spec/services/invoicing/generate_invoice_service_spec.rb`
- Use `describe '#call'` blocks for service objects

### CI Gate
- Run specs + coverage threshold

---

## Code Quality

- **Linters**: RuboCop, Brakeman
- **Checks on CI**: security scan, code analysis, and style
- **Method Guidelines**:
  - Methods < 10 lines
  - Classes < 150 LOC
  - Avoid inline conditionals for readability

### Example RuboCop Rules
```yaml
Metrics/MethodLength:
  Max: 10
Metrics/ClassLength:
  Max: 150
Style/FrozenStringLiteralComment:
  Enabled: true
```

---

## Development Workflow

1. **Review Context**: Read relevant `/doc` files first
2. **Feature Ticket**: Define feature in issue tracker
3. **Branch**: Create feature branch with `feature/<ticket-id>-<slug>`
4. **Test First**: Write RSpec specs before implementation
5. **Implement**: Code service objects and related components
6. **CSS**: Run `npm run build:css` after styling changes
7. **Review**: Submit PR with linters/tests passing
8. **Deploy**: Feature merges into `main` via PR with review

---

## Onboarding Checklist

- [ ] Clone repo & run setup script
- [ ] Create `.env` file with credentials
- [ ] Run `bundle exec rspec`
- [ ] Run `rubocop`
- [ ] Test CSS build: `npm run build:css`
- [ ] Review this guide and `/doc` folder
- [ ] Explore folder structure and service examples

---

## Final Thoughts

Maintain simplicity, modularity, and clarity. Prioritize TDD, meaningful abstraction, and reusable patterns. Always review historical context in `/doc` before starting new work to avoid regressions and ensure consistency.

