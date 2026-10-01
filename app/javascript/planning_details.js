/**
 * Planning Content Details Module
 * Handles displaying detailed information for content pieces in the planning calendar
 *
 * Rails-First Architecture (per CLAUDE.md):
 * - Content HTML is rendered server-side by Rails using presenters and partials
 * - JavaScript ONLY handles UI interactions (show/hide, scroll)
 * - NO HTML building or business logic in JavaScript
 * - Pattern: Controller → Presenter → View → Minimal JS for UX
 */

// VERSION MARKER - If you see this in console, you have the NEW code
console.log('🟢 planning_details.js - NEW VERSION - Rails-First Architecture - 2025-12-10-v2');
console.log('🟢 This version DOES NOT build HTML - Rails handles that');

// ============================================================================
// Content Details Display - UI Interactions Only
// ============================================================================

/**
 * Shows the content details section for a specific week
 * Content is already pre-rendered by Rails, we just show/hide it
 * @param {number} weekIndex - The week index (0-based)
 * @param {Object} _contentPiece - Unused, kept for API compatibility
 */
export function showContentDetails(weekIndex, _contentPiece) {
  console.log('showContentDetails called for week:', weekIndex);

  const weekDetailsId = `week-details-${weekIndex}`;
  const weekDetails = document.getElementById(weekDetailsId);

  if (!weekDetails) {
    console.error('Week details container not found:', weekDetailsId);
    return;
  }

  // Show the pre-rendered details section
  weekDetails.style.display = 'block';
  weekDetails.scrollIntoView({ behavior: 'smooth', block: 'start' });
}

/**
 * Hides the content details section
 * @param {string} weekDetailsId - The ID of the week details container
 */
export function hideContentDetails(weekDetailsId) {
  const weekDetails = document.getElementById(weekDetailsId);
  if (weekDetails) {
    weekDetails.style.display = 'none';
  }
}

// ============================================================================
// Initialization
// ============================================================================

// Track if handlers are already initialized to avoid duplicates
let handlersInitialized = false;

/**
 * Initialize event delegation for content detail cards
 */
export function initializeContentDetailsHandlers() {
  console.log('initializeContentDetailsHandlers called');

  // Prevent duplicate initialization
  if (handlersInitialized) {
    console.log('Handlers already initialized, skipping');
    return;
  }

  console.log('Initializing content details handlers for the first time');
  handlersInitialized = true;

  // Event delegation for content piece cards - attached to document, so it works even after Turbo updates
  document.addEventListener('click', function(e) {
    const contentCard = e.target.closest('.content-piece-card');
    if (contentCard) {
      console.log('Content card clicked via event delegation');
      e.preventDefault();
      e.stopPropagation();
      const weekIndex = parseInt(contentCard.getAttribute('data-week-index'));
      const contentPiece = JSON.parse(contentCard.getAttribute('data-content-piece'));
      console.log('Content card data:', { weekIndex, contentPiece });
      showContentDetails(weekIndex, contentPiece);
    }
  });
}

// Make functions available globally for onclick handlers in HTML
window.hideContentDetails = hideContentDetails;
window.showContentDetails = showContentDetails; // For debugging

console.log('🚀 planning_details.js module loaded - Rails-First Architecture');

// Auto-initialize when module loads
initializeContentDetailsHandlers();

// Also initialize on turbo:load for pages loaded via Turbo
document.addEventListener('turbo:load', () => {
  console.log('turbo:load event - reinitializing handlers');
  initializeContentDetailsHandlers();
});