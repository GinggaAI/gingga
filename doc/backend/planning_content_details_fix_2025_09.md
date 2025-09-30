# Planning Content Details - Issues and Solutions
**Date:** September 30, 2025
**Component:** Planning Page - Content Details Display
**Status:** ✅ Resolved

---

## 📋 Table of Contents
1. [Overview](#overview)
2. [Issues Encountered](#issues-encountered)
3. [Root Causes](#root-causes)
4. [Solutions Implemented](#solutions-implemented)
5. [Architecture Changes](#architecture-changes)
6. [Lessons Learned](#lessons-learned)
7. [Prevention Guidelines](#prevention-guidelines)

---

## Overview

### Context
The planning page displays content pieces in a calendar grid. When users click on content pieces (especially "in_production" status), they should see detailed information including:
- Hook, CTA, Description, Text Base
- Visual Notes, Template, Hashtags, KPI Focus
- **Scenes with voiceovers** (critical for reel creation)
- "Create Reel" button with complete data

### Initial Problem
Content details were not displaying when users clicked on content pieces in the planning calendar.

---

## Issues Encountered

### Issue #1: Click Event Not Firing on Content Cards
**Symptom:**
- Draft content details were visible when clicked
- "in_production" content did NOT show details when clicked
- No errors in console, events simply didn't fire

**Location:** `app/views/plannings/show.haml` lines ~1100-1110

**Code That Failed:**
```javascript
contentDiv.onclick = () => showContentDetails(weekIndex, contentPiece);
```

**Why It Failed:**
- The `onclick` property was assigned BEFORE the element had nested content
- When `innerHTML` was set with nested divs (for hook/CTA preview), clicks on child elements didn't bubble up properly
- The `onclick` handler was potentially overwritten by framework code

---

### Issue #2: AJAX Rendering with Devise/Warden Context Issues
**Symptom:**
```
Devise could not find the `Warden::Proxy` instance on your request environment.
```

**Location:** `app/services/planning/content_details_service.rb`

**Code That Failed:**
```ruby
ApplicationController.renderer.render(
  partial: "plannings/content_detail",
  locals: { content_piece: content_piece, presenter: presenter }
)
```

**Why It Failed:**
- `ApplicationController.renderer` tried to execute in a request-less context
- The renderer called `ApplicationController#default_url_options`
- `default_url_options` called `user_signed_in?` which requires Warden
- Warden doesn't exist outside HTTP request context
- The partial rendered `Ui::PlanningComponent` which used URL helpers like `new_reel_path`

**Error Chain:**
```
ApplicationController.renderer
  → default_url_options
    → user_signed_in?
      → warden (NOT AVAILABLE)
        → 💥 ERROR
```

---

### Issue #3: Incomplete Data Sent to Reel Creation
**Symptom:**
- "Create Reel" button appeared but reels were created without scene voiceovers
- Only title and description were passed
- Voiceovers and other scene details were missing

**Location:** `app/views/plannings/show.haml` ~line 1355

**Code That Failed:**
```javascript
const reelData = {
  title: content.title,
  description: content.description,
  scenes: content.scenes || [],  // ❌ Scenes included but not properly mapped
  template: content.template
};
```

**Why It Failed:**
- Object was too shallow - didn't explicitly extract all scene properties
- Some nested properties might not serialize correctly
- No console logging to verify what was actually being sent

---

## Root Causes

### 1. **Violation of Rails Doctrine**
The original implementation used heavy AJAX to render content details server-side. This violated the **Rails-first principle** from CLAUDE.md:

> "JavaScript ONLY for: UI interactions, form submissions, DOM manipulation"
> "Rails handles: Data processing, business rules, conditional logic, formatting"

**Problem:** We tried to do server-side rendering AFTER page load via AJAX, which introduced authentication context issues.

---

### 2. **Event Delegation Not Used**
Modern web apps with dynamic content need **event delegation** - attaching listeners to parent elements rather than individual child elements.

**What We Did Wrong:**
```javascript
// ❌ Attaching to individual elements that change
contentDiv.addEventListener('click', handler);
```

**What We Should Have Done:**
```javascript
// ✅ Event delegation on document
document.addEventListener('click', function(e) {
  const card = e.target.closest('.content-piece-card');
  if (card) { handler(); }
});
```

---

### 3. **Context-Dependent Rendering**
Trying to render Rails partials outside HTTP request context breaks:
- Authentication helpers (`current_user`, `user_signed_in?`)
- URL helpers (`new_reel_path`, etc.)
- Devise/Warden middleware
- Flash messages, session data

**The service tried to render a view that expected full Rails context but was called from a standalone renderer.**

---

## Solutions Implemented

### Solution #1: Event Delegation Pattern
**File:** `app/views/plannings/show.haml` lines 235-246

**What Changed:**
1. Added `data-*` attributes to content cards:
```javascript
contentDiv.setAttribute('data-week-index', weekIndex);
contentDiv.setAttribute('data-content-piece', JSON.stringify(contentPiece));
contentDiv.classList.add('content-piece-card');
```

2. Implemented global event delegation in `turbo:load`:
```javascript
document.addEventListener('click', function(e) {
  const contentCard = e.target.closest('.content-piece-card');
  if (contentCard) {
    e.preventDefault();
    e.stopPropagation();
    const weekIndex = parseInt(contentCard.getAttribute('data-week-index'));
    const contentPiece = JSON.parse(contentCard.getAttribute('data-content-piece'));
    showContentDetails(weekIndex, contentPiece);
  }
});
```

**Why It Works:**
- Event listener is attached ONCE to document
- Uses `.closest()` to find parent card regardless of which child element was clicked
- Data is stored in attributes, not closures
- Works with dynamically added content

---

### Solution #2: Client-Side HTML Generation (Rails-First Approach)
**File:** `app/views/plannings/show.haml` lines 1161-1392

**What Changed:**
Eliminated AJAX entirely. Moved to pure client-side rendering:

```javascript
function showContentDetails(weekIndex, contentPiece) {
  const weekDetailsId = `week-details-${weekIndex}`;
  const weekDetails = document.getElementById(weekDetailsId);
  const detailsGrid = weekDetails.querySelector('.content-details-grid');

  // Build HTML directly from data already in DOM
  const detailHTML = buildContentDetailHTML(contentPiece);
  detailsGrid.innerHTML = detailHTML;

  weekDetails.style.display = 'block';
  weekDetails.scrollIntoView({ behavior: 'smooth', block: 'start' });
}
```

**New Function:** `buildContentDetailHTML(content)`
- ~200 lines of JavaScript that builds the complete detail view
- Includes all fields: hook, CTA, description, scenes, etc.
- Creates "Create Reel" button with proper data
- No server round-trip needed

**Why It Works:**
- All data is already loaded in `window.currentPlan` from server
- No authentication context needed
- JavaScript only does UI work (show/hide, build HTML)
- Follows Rails Doctrine: server sends data once, JS handles interaction

---

### Solution #3: Complete Data Mapping for Reel Creation
**File:** `app/views/plannings/show.haml` lines 1355-1395

**What Changed:**
Explicit mapping of ALL scene properties:

```javascript
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
    voiceover: scene.voiceover,           // ← Critical for reel creation
    on_screen_text: scene.on_screen_text,
    voice_id: scene.voice_id,
    avatar_id: scene.avatar_id,
    duration: scene.duration
  })),
  beats: content.beats || [],
  shotplan: content.shotplan || {}
};

const reelDataEncoded = encodeURIComponent(JSON.stringify(reelData));
console.log('Reel data being sent:', reelData); // ← Debug logging
```

**Why It Works:**
- Explicitly maps every scene property we need
- Uses `.map()` to ensure clean object structure
- Includes `console.log` for verification
- Encodes properly for URL parameter
- Includes fallbacks for missing data (`|| []`, `|| {}`)

---

## Architecture Changes

### Before (AJAX-Heavy, Anti-Pattern)
```
User clicks content
  ↓
JavaScript makes fetch() to /planning/content_details
  ↓
Rails ContentDetailsController receives request
  ↓
ContentDetailsService.render_content_details
  ↓
ApplicationController.renderer.render (tries to render partial)
  ↓
Partial needs current_user, URL helpers → 💥 FAILS
  ↓
Returns 500 error to JavaScript
  ↓
User sees error message
```

**Problems:**
- Network round-trip for data already on page
- Authentication context issues
- Complexity in error handling
- Slow user experience

---

### After (Rails-First, Correct Pattern)
```
Server renders planning page
  ↓
Includes window.currentPlan with ALL data
  ↓
User clicks content (JavaScript handles)
  ↓
Extract data from data-content-piece attribute
  ↓
Build HTML string with buildContentDetailHTML()
  ↓
Insert HTML into existing week-details container
  ↓
Show container (display: block)
  ↓
Done - instant display, no server call
```

**Benefits:**
- Zero network latency
- No authentication issues
- Simple error handling (data already validated by server)
- Fast, responsive UI
- Follows Rails Doctrine

---

## Lessons Learned

### 1. **Follow Rails Doctrine Strictly**
From CLAUDE.md:
> "JavaScript ONLY for: UI interactions, form submissions, DOM manipulation"

**Don't:** Try to render Rails views via AJAX after page load
**Do:** Have server render all data once, use JS to show/hide

---

### 2. **Event Delegation for Dynamic Content**
**Don't:** Attach event listeners to dynamically created elements
**Do:** Use event delegation on a stable parent (document, container)

**Pattern:**
```javascript
// ❌ WRONG
elements.forEach(el => el.addEventListener('click', handler));

// ✅ RIGHT
document.addEventListener('click', (e) => {
  if (e.target.matches('.target-class')) handler(e);
});
```

---

### 3. **Authentication Context is Request-Scoped**
**Don't:** Try to use `current_user`, `user_signed_in?`, or Devise helpers outside HTTP request context
**Do:** Pass necessary data as parameters or render everything in the initial request

**When using `ApplicationController.renderer`:**
- It creates a standalone rendering context
- No session, no authentication, no request object
- URL helpers may fail if they depend on request data
- Use `ActionController::Base.renderer` for context-free rendering OR
- Pass all needed data explicitly without depending on controller helpers

---

### 4. **Data Completeness for Integrations**
When passing data between components (planning → reel creation):
- **Explicitly map all required fields** - don't assume object spreading works
- **Add console.log** to verify data before sending
- **Document what data is needed** in comments
- **Use TypeScript/JSDoc** if possible for type safety

---

### 5. **Defensive Coding with BrandResolver**
**File:** `app/services/planning/brand_resolver.rb`

Added nil check:
```ruby
def call
  return nil unless @user
  @user.current_brand
end
```

**Lesson:** Always validate inputs in service objects, even if "impossible" to be nil.

---

## Prevention Guidelines

### ✅ DO's

1. **Server Renders Data Once**
   - Send all content data in initial page load
   - Store in `window.currentPlan` or data attributes
   - JavaScript only manipulates what's already there

2. **Use Event Delegation**
   - Attach listeners to stable parent elements
   - Use `.closest()` to find target elements
   - Works with Turbo and dynamic content

3. **Explicit Data Mapping**
   - Map all required properties explicitly
   - Add console.log for debugging
   - Document what data each component needs

4. **Test with Real Data**
   - Use actual production-like data structures
   - Test with content that has scenes, beats, all fields
   - Verify data in console before submitting

5. **Follow CLAUDE.md Guidelines**
   - Rails Doctrine: Convention over Configuration
   - Fat Models, Thin Controllers
   - **POST-REDIRECT-GET** for forms
   - **No business logic in JavaScript**

---

### ❌ DON'Ts

1. **Don't Use AJAX to Render Rails Partials**
   - Causes authentication context issues
   - Adds unnecessary complexity
   - Violates Rails-first principle

2. **Don't Attach Events to Dynamic Elements**
   - Use event delegation instead
   - Prevents memory leaks
   - Works better with Turbo

3. **Don't Assume Object Spreading**
   - JavaScript object spread (`...obj`) may not preserve all properties
   - Explicitly map properties you need
   - Test the actual data being sent

4. **Don't Use ApplicationController.renderer for Complex Views**
   - Use it only for simple, context-free partials
   - If partial needs authentication, render in controller action instead
   - Consider ActionController::Base.renderer for neutral context

5. **Don't Skip Nil Checks in Services**
   - Always validate inputs
   - Return early with clear error messages
   - Handle edge cases defensively

---

## Code Reference Summary

### Key Files Changed

1. **`app/views/plannings/show.haml`**
   - Lines 235-246: Event delegation setup
   - Lines 1103-1106: Data attributes on content cards
   - Lines 1161-1392: Client-side HTML generation
   - Lines 1355-1395: Complete reel data mapping

2. **`app/services/planning/brand_resolver.rb`**
   - Lines 11-13: Nil check for user

3. **`app/services/planning/content_details_service.rb`**
   - **NOT USED ANYMORE** - entire AJAX approach removed

4. **`app/controllers/planning/content_details_controller.rb`**
   - **CAN BE REMOVED** - endpoint no longer needed

5. **`app/views/plannings/_content_detail.html.haml`**
   - **CAN BE REMOVED** - partial no longer rendered via AJAX

---

## Testing Checklist

When working on planning content details, verify:

- [ ] Click on draft content shows details
- [ ] Click on in_production content shows details
- [ ] All fields display correctly (hook, CTA, description, etc.)
- [ ] Scenes display with all properties (voiceover, visual, etc.)
- [ ] "Create Reel" button appears for in_production content with template
- [ ] Clicking "Create Reel" navigates to `/reels/new` with complete data
- [ ] Console shows `Reel data being sent:` with all scene voiceovers
- [ ] Close button (×) hides the details section
- [ ] Multiple content pieces can be viewed in sequence
- [ ] Works with Turbo navigation (back/forward browser buttons)
- [ ] No console errors
- [ ] No 500 errors in server logs

---

## Related Documentation

- **CLAUDE.md**: Main project guidelines (Rails Doctrine, POST-REDIRECT-GET)
- **`/doc/frontend/viewcomponent_vs_helper_refactor_2025_09.md`**: ViewComponent guidelines
- **`/doc/backend/background_jobs_implementation_guide.md`**: Background job patterns

---

## Future Improvements

### Consider Moving to ViewComponent
The `buildContentDetailHTML()` function is ~200 lines of JavaScript string concatenation. Consider:

1. Create `Ui::ContentDetailComponent`
2. Render all details server-side in hidden divs
3. JavaScript just shows/hides pre-rendered content
4. Even more Rails-first approach

**Benefits:**
- No HTML string building in JavaScript
- Server-side XSS protection
- Easier to maintain
- Better i18n support
- Type safety with Ruby

**Trade-off:**
- Slightly larger initial page size (all details pre-rendered)
- More DOM elements even if not visible

### Consider Hotwire/Turbo Frames
Instead of custom show/hide logic, use Turbo Frames:
```haml
= turbo_frame_tag "week-#{week_number}-details" do
  / Details content here
```

Then load content on demand with Turbo, which handles authentication properly.

---

## Conclusion

The root cause was **violating Rails Doctrine** by trying to render Rails views outside HTTP request context. The solution was to **embrace Rails-first development**: server sends all data once, JavaScript only handles UI interactions.

**Key Takeaway:** When you find yourself fighting with authentication context, request objects, or Devise/Warden errors in background rendering, step back and ask: "Should the server have sent this data in the initial response?"

The answer is usually **yes**.

---

**Document Owner:** Development Team
**Last Updated:** September 30, 2025
**Next Review:** When adding new planning features or modifying content detail display