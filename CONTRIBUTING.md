# Rails Codebase Best Practices Guide for Claude-Code

## Overview
This document establishes a unified standard for contributing to a high-quality, scalable Ruby on Rails codebase. It's optimized for service-oriented architectures with a strong emphasis on test coverage, code clarity, and automated quality gates.

---

## 1. Project Structure
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

## 2. Service-Oriented Architecture
- Group domain logic into `app/services/<domain>/<action>_service.rb`
- Services should:
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

## 3. Testing Standards
- **Framework**: RSpec + FactoryBot + Shoulda Matchers
- **Folder Mirroring**: `spec/` mirrors `app/` structure
- **Test Type Separation**: `spec/services`, `spec/models`, etc.
- **Factories**: defined under `spec/support/factories/`
- **Coverage Goal**: 100% on service, model, and controller logic

### Naming
- Describe use cases: `spec/services/invoicing/generate_invoice_service_spec.rb`
- Use `describe '#call'` blocks for service objects

### CI Gate
- Run specs + `simplecov` threshold

---

## 4. Code Quality
- **Linters**: RuboCop, Reek, Brakeman
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

## 5. Development Workflow
1. **Feature Ticket**: Define feature in issue tracker
2. **Branch**: Create feature branch with `feature/<ticket-id>-<slug>`
3. **Test First**: Write RSpec specs before implementation
4. **Implement**: Code service objects and related components
5. **Review**: Submit PR with linters/tests passing
6. **Deploy**: Feature merges into `main` via PR with review

---

## 6. Onboarding Checklist
- [ ] Clone repo & run setup script
- [ ] Create `.env` file with credentials
- [ ] Run `bundle exec rspec`
- [ ] Run `rubocop`
- [ ] Review this guide
- [ ] Explore folder structure and service examples

---

## Final Thoughts
Maintain simplicity, modularity, and clarity. Prioritize TDD, meaningful abstraction, and reusable patterns. Use AI tools like Claude-Code to explore, but ensure code reflects human-centered design and system integrity.

