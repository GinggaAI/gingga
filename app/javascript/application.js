// Entry point for the build script in your package.json
import "@hotwired/turbo-rails"
import "./controllers"
import "./planning_calendar"

console.log('🔵 application.js loading...');

// Import planning details module - this imports and executes the module
import "./planning_details"

console.log('🔵 application.js loaded - all imports done');
