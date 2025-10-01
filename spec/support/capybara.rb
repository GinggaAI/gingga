# frozen_string_literal: true

require 'capybara/rspec'
require 'selenium-webdriver'

# Configure Capybara to use rack_test for non-JS tests and headless chromium for JS tests
RSpec.configure do |config|
  # Register custom driver for headless chromium
  Capybara.register_driver :headless_chromium do |app|
    options = Selenium::WebDriver::Chrome::Options.new
    options.binary = '/usr/bin/chromium-browser'
    options.add_argument('--headless=new')
    options.add_argument('--no-sandbox')
    options.add_argument('--disable-dev-shm-usage')
    options.add_argument('--disable-gpu')
    options.add_argument('--window-size=1400,1400')

    Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
  end

  # Use rack_test for non-JavaScript tests (faster)
  config.before(:each, type: :system) do
    driven_by :rack_test
  end

  # Use headless chromium for JavaScript tests
  config.before(:each, type: :system, js: true) do
    driven_by :headless_chromium
  end
end
