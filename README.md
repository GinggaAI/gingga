# Gingga Rails Application

An AI-powered content strategy platform built with Ruby on Rails.

---

## 🚀 For Contributors

**IMPORTANT**: Before writing any code, please read [CLAUDE.md](./CLAUDE.md) - our comprehensive contributor guide that covers development standards, testing requirements, and documentation practices.

[CLAUDE.md](./CLAUDE.md) includes:
- Development standards and best practices
- Testing requirements (90%+ coverage)
- Service-oriented architecture guidelines
- Security best practices
- Complete development workflow

---

## 📁 Documentation Structure

All project documentation is organized in the `/doc` directory:

- **`/doc/backend/`** - Backend architecture, API, services, and integrations
- **`/doc/frontend/`** - Frontend components, styling, and JavaScript  
- **`/doc/manual_test/`** - Testing guides and QA procedures

---

## 🏗️ Quick Start

### Prerequisites
- Ruby 3.4.2+
- Rails 8.0+
- PostgreSQL
- Node.js and npm
- Docker (for development services)

### Setup

```bash
# Clone repository
git clone git@github.com:vlaguzman/gingga.git
cd gingga/

# Install dependencies
bundle install
npm install

# Setup database
docker-compose up -d        # Start PostgreSQL and Selenium
bundle exec rails db:setup  # Create and migrate database

# Verify installation
bundle exec rspec           # Run test suite
npm run build:css          # Build CSS

# Start development server
bin/dev                    # Runs Rails server + CSS watcher
```

The application will be available at http://localhost:3000

---

## 🧪 Development Workflow

### Before Making Changes
1. Read [CLAUDE.md](./CLAUDE.md) contributor guide
2. Review relevant documentation in `/doc`
3. Run existing tests to ensure clean slate

### Development Process
```bash
# Create feature branch
git checkout -b feature/your-feature-name

# Write tests first (TDD approach)
# Implement feature
# Ensure tests pass with 90%+ coverage

# Run quality checks before committing
bundle exec rspec              # All tests must pass
bundle exec rubocop           # Code style compliance
bundle exec brakeman          # Security scan
npm run build:css             # Rebuild CSS assets

# Alternative: Run all checks together
bash bin/shot                 # Comprehensive verification script
```

### Testing
```bash
# Run full test suite
bundle exec rspec

# Run specific test files
bundle exec rspec spec/models/
bundle exec rspec spec/services/some_service_spec.rb

# Check test coverage
open coverage/index.html
```

---

## 🏗️ Architecture

### Backend
- **Ruby on Rails 8.0** with modern conventions
- **Service-oriented architecture** for business logic
- **PostgreSQL** with JSONB for flexible data storage
- **API integrations** with OpenAI, Heygen, and Kling
- **Comprehensive test coverage** with RSpec

### Frontend  
- **Server-rendered HTML** with Rails views
- **Hotwire** (Turbo + Stimulus) for enhanced interactivity
- **ViewComponent** for reusable UI components
- **Tailwind CSS** with design tokens
- **React islands** (approval required)

### Key Technologies
- **Authentication**: Devise
- **Background Jobs**: Sidekiq (configured)
- **Caching**: Redis (configured) 
- **File Storage**: Active Storage
- **Testing**: RSpec, FactoryBot, Capybara
- **Code Quality**: RuboCop, Brakeman
- **CSS Processing**: Tailwind CSS with npm

---

## 🔧 Available Commands

### Development
```bash
bin/dev                    # Start Rails server + CSS watcher
rails server              # Rails server only  
npm run build:css          # Compile CSS
npm run build:css -- --watch  # Watch CSS changes
```

### Testing and Quality
```bash
bundle exec rspec          # Run all tests
bundle exec rubocop        # Code style check
bundle exec brakeman       # Security scan
bash bin/shot             # Run all quality checks
```

### Database
```bash
rails db:migrate          # Run migrations
rails db:seed             # Seed database
rails db:reset            # Reset database
```

---

## 📋 Quality Standards

We maintain high code quality standards:

- **✅ 90%+ test coverage** on all new/modified files
- **✅ Zero test failures** before merging
- **✅ RuboCop compliance** for code style
- **✅ Security scan passing** with Brakeman
- **✅ Comprehensive documentation** for all changes

---

## 🔒 Security

- All API keys encrypted at rest
- Input validation on all endpoints
- SQL injection prevention with parameterized queries
- XSS protection in all views
- Regular security scanning with Brakeman
- No secrets committed to repository

---

## 🚀 Deployment

The application is configured for deployment with:
- Dockerfile for containerization
- Capfile for Capistrano deployment
- Environment-based configuration
- Asset precompilation setup
- Database migration automation

---

## 📞 Support

### Documentation
- **[CLAUDE.md](./CLAUDE.md)** - Main contributor guide
- **`/doc/backend/`** - Backend architecture and services
- **`/doc/frontend/`** - Frontend components and styling
- **`/doc/manual_test/`** - Testing procedures

### Getting Help
1. Check relevant documentation in `/doc`
2. Review test output and logs
3. Look for similar implementations in codebase
4. Consult team members with documented context

---

## 🎯 Project Vision

Gingga is an AI-powered platform for creating comprehensive content strategies. It leverages cutting-edge AI services to help brands develop, manage, and optimize their content across multiple channels with data-driven insights and automated workflows.

---

**Ready to contribute?** Start with [CLAUDE.md](./CLAUDE.md) to understand our development standards and practices.

**Last Updated**: August 19, 2025