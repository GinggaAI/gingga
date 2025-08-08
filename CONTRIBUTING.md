### Contributing Guide

This project follows clear standards for both backend and frontend contributions. Please read this guide fully before opening a PR.

## Frontend Mode (Rails + Hotwire)

We use Rails-rendered HTML with Hotwire (Turbo + Stimulus) and ViewComponent for reusable UI. Follow the standards in `doc/frontend.md`.

- Read the guide: `doc/frontend.md`

## Rails Codebase Best Practices (Backend)

This repo uses a service-oriented structure with strong testing and quality gates.

- Project structure mirrors Rails conventions and adds `app/services`, `app/forms`, and `app/presenters`.
- Services live under `app/services/<domain>/<action>_service.rb` and follow SRP.

Testing standards:
- RSpec + FactoryBot + Shoulda Matchers
- `spec/` mirrors `app/` structure; use clear naming
- Aim for high coverage on service/model/controller logic

Code quality:
- Linters: RuboCop, Brakeman (and others as configured)
- Keep methods small and classes focused

Development workflow:
1. Create a feature ticket
2. Branch: `feature/<ticket-id>-<slug>`
3. Test-first: write specs, then implement
4. Open PR with all checks passing

Onboarding checklist:
- Clone repo and run setup
- Prepare environment variables
- Run `bundle exec rspec` and `rubocop`
- Read docs in `/doc`

