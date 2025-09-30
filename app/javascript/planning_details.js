/**
 * Planning Content Details Module
 * Handles displaying detailed information for content pieces in the planning calendar
 *
 * This module follows Rails-first principles:
 * - All data comes from the server in the initial page load
 * - JavaScript only handles UI interactions (show/hide, build display)
 * - No AJAX calls for rendering content details
 */

// ============================================================================
// Content Details Display
// ============================================================================

/**
 * Shows detailed information for a content piece
 * @param {number} weekIndex - The week index (0-based)
 * @param {Object} contentPiece - The content piece data
 */
export function showContentDetails(weekIndex, contentPiece) {
  console.log('showContentDetails called:', { weekIndex, contentPiece });

  const weekDetailsId = `week-details-${weekIndex}`;
  const weekDetails = document.getElementById(weekDetailsId);

  if (!weekDetails) {
    console.error('Week details container not found:', weekDetailsId);
    return;
  }

  const detailsGrid = weekDetails.querySelector('.content-details-grid');

  // Clear previous details
  detailsGrid.innerHTML = '';

  // Build content detail HTML
  const detailHTML = buildContentDetailHTML(contentPiece);
  detailsGrid.innerHTML = detailHTML;

  // Show the details section
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
    // Clear the content details
    const detailsGrid = weekDetails.querySelector('.content-details-grid');
    if (detailsGrid) {
      detailsGrid.innerHTML = '';
    }
  }
}

// ============================================================================
// HTML Building Functions
// ============================================================================

/**
 * Builds the HTML for content detail display
 * @param {Object} content - The content piece data
 * @returns {string} HTML string for the content detail
 */
function buildContentDetailHTML(content) {
  const contentId = `content-${Date.now()}-${Math.floor(Math.random() * 1000)}`;
  const title = content.title || 'Content Draft';
  const platform = content.platform || 'Instagram';
  const contentType = content.type || content.content_type || 'Post';
  const status = content.status || 'draft';
  const pilar = content.pilar || content.pillar || '';

  const statusClass = getStatusClass(status);

  let html = buildHeaderSection(contentId, title, platform, contentType, status, pilar, statusClass);
  html += buildMainContentSection(content);
  html += buildSchedulingSection(content);
  html += buildScenesSection(content);
  html += buildCreateReelButton(content, status);
  html += '</div>';

  return html;
}

/**
 * Builds the header section of content detail
 */
function buildHeaderSection(contentId, title, platform, contentType, status, pilar, statusClass) {
  return `
    <div id="${contentId}" class="bg-white p-4 rounded shadow-sm ${statusClass}">
      <div class="flex justify-between items-start mb-3">
        <div>
          <h4 class="text-lg font-semibold text-gray-900">${escapeHtml(title)}</h4>
          <div class="flex items-center gap-2 mt-1">
            <span class="text-xs px-2 py-1 rounded font-medium ${statusClass}">${status.toUpperCase().replace('_', ' ')}</span>
            <span class="bg-gray-100 text-gray-700 text-xs px-2 py-1 rounded">${platform} ${contentType}</span>
            ${pilar ? `<span class="bg-indigo-100 text-indigo-700 text-xs px-2 py-1 rounded">Pillar ${pilar}</span>` : ''}
          </div>
        </div>
        <button class="text-gray-400 hover:text-gray-600 text-lg font-bold" onclick="this.closest('.bg-white').remove()">&times;</button>
      </div>
      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">`;
}

/**
 * Builds the main content sections (left and right columns)
 */
function buildMainContentSection(content) {
  let html = '<div class="space-y-3">';

  // Left column
  html += buildContentField(content.hook, '🎣 Hook', 'bg-blue-50');
  html += buildContentField(content.description, '📝 Description', 'bg-yellow-50');
  html += buildContentField(content.cta, '📢 Call to Action', 'bg-green-50');
  html += buildContentField(content.text_base, '📄 Text Base', 'bg-slate-50', true);

  html += '</div><div class="space-y-3">';

  // Right column
  html += buildContentField(content.visual_notes, '🎨 Visual Notes', 'bg-purple-50');
  html += buildContentField(content.template?.replace(/_/g, ' '), '🎬 Template', 'bg-indigo-50');
  html += buildContentField(content.hashtags, '#️⃣ Hashtags', 'bg-cyan-50');
  html += buildContentField(content.kpi_focus, '🎯 KPI Focus', 'bg-orange-50');
  html += buildContentField(content.success_criteria, '📊 Success Criteria', 'bg-teal-50');

  html += '</div></div>';

  return html;
}

/**
 * Builds a single content field section
 */
function buildContentField(value, label, bgClass, preserveWhitespace = false) {
  if (!value) return '';

  const whitespaceClass = preserveWhitespace ? ' whitespace-pre-line' : '';

  return `
    <div class="${bgClass} p-3 rounded">
      <h5 class="font-medium text-gray-900 mb-1">${label}</h5>
      <p class="text-sm text-gray-700${whitespaceClass}">${escapeHtml(value)}</p>
    </div>`;
}

/**
 * Builds the scheduling section
 */
function buildSchedulingSection(content) {
  if (!content.publish_date && !content.scheduled_day) return '';

  let html = `
    <div class="mt-4 p-3 bg-blue-50 rounded">
      <h5 class="font-medium text-gray-900 mb-2">📅 Scheduling</h5>
      <div class="flex gap-4 text-sm">`;

  if (content.publish_date) {
    html += `<span class="text-gray-700"><strong>Publish Date:</strong> ${escapeHtml(content.publish_date)}</span>`;
  }

  if (content.scheduled_day) {
    html += `<span class="text-gray-700"><strong>Day:</strong> ${escapeHtml(content.scheduled_day)}</span>`;
  }

  html += '</div></div>';

  return html;
}

/**
 * Builds the scenes section if scenes exist
 */
function buildScenesSection(content) {
  if (!content.scenes || content.scenes.length === 0) return '';

  let html = `
    <div class="mt-4 p-3 bg-purple-50 rounded border-l-4 border-purple-500">
      <h5 class="font-medium text-gray-900 mb-3">🎬 Shot Plan Scenes</h5>
      <div class="space-y-3">`;

  content.scenes.forEach((scene, idx) => {
    html += buildSceneCard(scene, idx);
  });

  html += '</div></div>';

  return html;
}

/**
 * Builds a single scene card
 */
function buildSceneCard(scene, idx) {
  const sceneTitle = scene.scene_number ? `Scene ${scene.scene_number}` : `Scene ${idx + 1}`;
  const roleTitle = scene.role ? ` - ${scene.role}` : '';

  let html = `
    <div class="bg-white p-3 rounded border-l-2 border-purple-300">
      <div class="flex items-start justify-between mb-2">
        <h6 class="font-semibold text-sm text-purple-800">${sceneTitle}${roleTitle}</h6>
        ${scene.duration ? `<span class="text-xs text-gray-500 bg-gray-100 px-2 py-1 rounded">${escapeHtml(scene.duration)}</span>` : ''}
      </div>`;

  if (scene.description) {
    html += `<p class="text-sm text-gray-700 mb-2">${escapeHtml(scene.description)}</p>`;
  }

  if (scene.visual) {
    html += `<p class="text-xs text-gray-600"><strong>Visual:</strong> ${escapeHtml(scene.visual)}</p>`;
  }

  if (scene.on_screen_text) {
    html += `<p class="text-xs text-gray-600"><strong>On Screen Text:</strong> ${escapeHtml(scene.on_screen_text)}</p>`;
  }

  if (scene.voiceover) {
    html += `<p class="text-xs text-gray-600"><strong>Voiceover:</strong> ${escapeHtml(scene.voiceover)}</p>`;
  }

  html += '</div>';

  return html;
}

/**
 * Builds the "Create Reel" button if applicable
 */
function buildCreateReelButton(content, status) {
  if (!content.template || status === 'draft') return '';

  // Build complete reel data including all scene details
  const reelData = {
    title: content.title,
    description: content.description,
    template: content.template,
    text_base: content.text_base,
    hook: content.hook,
    cta: content.cta,
    scenes: (content.scenes || []).map(scene => ({
      id: scene.id,
      role: scene.role,
      type: scene.type,
      visual: scene.visual,
      voiceover: scene.voiceover,
      on_screen_text: scene.on_screen_text,
      voice_id: scene.voice_id,
      avatar_id: scene.avatar_id,
      duration: scene.duration
    })),
    beats: content.beats || [],
    shotplan: content.shotplan || {}
  };

  const reelDataEncoded = encodeURIComponent(JSON.stringify(reelData));
  console.log('Reel data being sent:', reelData);

  // Get brand and locale from page data attributes or URL
  const brandSlug = document.body.dataset.brandSlug || window.location.pathname.split('/')[1];
  const locale = document.body.dataset.locale || window.location.pathname.split('/')[2];

  return `
    <div class="mt-4 p-4" style="background: linear-gradient(to right, rgb(240 253 244), rgb(239 246 255)); border-left: 4px solid rgb(34 197 94); border-radius: 0.5rem;">
      <div class="flex items-center justify-between">
        <div>
          <h5 class="font-medium text-gray-900 mb-1">🎬 Create Reel</h5>
          <p class="text-sm text-gray-600">Create this reel from the planning data</p>
        </div>
        <a href="/${brandSlug}/${locale}/reels/new?template=${content.template}&smart_planning_data=${reelDataEncoded}" class="inline-flex items-center gap-2 font-medium px-4 py-2 rounded-lg transition-colors duration-200" style="background-color: rgb(22 163 74); color: white;" onmouseover="this.style.backgroundColor='rgb(21 128 61)'" onmouseout="this.style.backgroundColor='rgb(22 163 74)'">
          <span>🚀</span>
          <span>Create Reel</span>
        </a>
      </div>
    </div>`;
}

// ============================================================================
// Utility Functions
// ============================================================================

/**
 * Gets CSS class for status badge
 */
function getStatusClass(status) {
  const statusColors = {
    'draft': 'bg-gray-100 text-gray-700 border-gray-500',
    'in_production': 'bg-blue-100 text-blue-800 border-blue-500',
    'ready_for_review': 'bg-yellow-100 text-yellow-800 border-yellow-500',
    'approved': 'bg-green-100 text-green-800 border-green-500'
  };

  return statusColors[status] || statusColors['draft'];
}

/**
 * Escapes HTML to prevent XSS
 */
function escapeHtml(unsafe) {
  if (!unsafe) return '';
  return unsafe
    .toString()
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;");
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

console.log('🚀 planning_details.js module loaded - v2025.09.30-13:30');

// Auto-initialize when module loads
initializeContentDetailsHandlers();

// Also initialize on turbo:load for pages loaded via Turbo
document.addEventListener('turbo:load', () => {
  console.log('turbo:load event - checking if need to reinitialize');
  initializeContentDetailsHandlers();
});