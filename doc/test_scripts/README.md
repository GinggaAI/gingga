# Test Scripts

This directory contains utility scripts for testing various functionalities of the Gingga application.

## Available Scripts

### `test_voxa_refinement.rb`
Tests the complete Voxa content refinement process step by step.

**Usage:**
```bash
bundle exec rails runner doc/test_scripts/test_voxa_refinement.rb
```

**What it tests:**
1. Verifies existing strategy
2. Checks SolidQueue workers status
3. Simulates content refinement parameters
4. Executes the Planning::ContentRefinementService
5. Verifies job creation and enqueueing
6. Provides monitoring instructions

**Prerequisites:**
- At least one completed CreasStrategyPlan in the database
- SolidQueue workers running
- Voxa integration configured

## Adding New Test Scripts

When adding new test scripts:

1. Name them descriptively (e.g., `test_heygen_integration.rb`)
2. Include comprehensive step-by-step logging
3. Handle errors gracefully with proper exit codes
4. Update this README with usage instructions
5. Follow the existing script structure pattern

## Usage Notes

- All scripts should be run from the Rails root directory
- Scripts use `bundle exec rails runner` to load the Rails environment
- Check SolidQueue status before running job-related tests
- Scripts may modify database state - be careful in production