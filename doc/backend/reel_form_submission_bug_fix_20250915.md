# Reel Form Submission Bug Fix - September 15, 2025

## Problem Summary

Scene-based reel creation was completely broken after the "js to ruby" refactor (commit e9d678a). Users could load the form but submission would fail silently, creating empty draft reels instead of triggering HeyGen video generation.

## Root Cause Analysis

### The "js to ruby" Refactor Issue (commit e9d678a)

The refactor introduced a critical flaw in the form submission flow by changing how reels were initialized:

**Before (Working):**
```ruby
def scene_based
  @reel = current_user.reels.build(mode: "scene_based")  # Unsaved reel
  3.times { |i| @reel.reel_scenes.build(scene_number: i + 1) }  # Built scenes
end
```

**After "js to ruby" (Broken):**
```ruby
def new
  result = Reels::InitializationService.new(user: current_user, template: params[:template]).call
  @reel = result.data[:reel]  # This reel was SAVED to database
end
```

### The Chain of Problems

1. **InitializationService saved reel during GET request**
   - `initialize_reel` method called `reel.save` during form load
   - This created a persisted reel record before form submission

2. **Rails form_with behavior changed**
   - `form_with model: @reel` detects persisted records
   - For new records: generates POST request to create
   - For persisted records: generates PATCH request to update

3. **PATCH route didn't exist**
   ```
   Started PATCH "/en/reels/bfe6851a-1243-4ac1-8b51-870d17c103df"
   ActionController::RoutingError (No route matches [PATCH])
   ```

4. **Fallback to GET route**
   - Failed PATCH redirected to GET route
   - This triggered InitializationService again
   - Created another empty reel in database
   - Form never actually submitted data

### Form URL Issues

Initially also had a form action URL problem:
```haml
# Wrong - forces GET route
= form_with model: @reel, url: scene_based_reels_path, local: true

# Fixed - lets Rails determine correct route
= form_with model: @reel, local: true
```

## Solution Implementation

### 1. Restore Original Form Pattern
```ruby
def new
  # Create unsaved reel with built scenes (like original working code)
  @reel = current_user.reels.build(template: params[:template], status: "draft")

  # For scene-based templates, build the scene structure
  if params[:template].in?(%w[only_avatars avatar_and_video])
    3.times { |i| @reel.reel_scenes.build(scene_number: i + 1) }
  end
end
```

### 2. Adapt Smart Planning Preload
The "js to ruby" refactor added smart planning preload functionality that needed to be preserved:

**Before (Broken for unsaved reels):**
```ruby
def preload_scenes_from_shotplan(scenes)
  @reel.reel_scenes.destroy_all  # Tries to destroy from unsaved reel
  @reel.reel_scenes.create!(...)  # Tries to create before reel is saved
end
```

**After (Fixed for unsaved reels):**
```ruby
def preload_scenes_from_shotplan(scenes)
  @reel.reel_scenes.clear  # Clear built scenes from memory
  @reel.reel_scenes.build(...)  # Build scenes for form
end
```

### 3. Form Template Compatibility
The refactor changed templates to use `@presenter.scene_data_for(i)` which expects scenes to exist:

```ruby
# In presenter
def scene_data_for(index)
  reel.reel_scenes[index]&.attributes || {}
end
```

By building 3 scenes in the controller, this method now works correctly.

## Technical Flow (Fixed)

### Normal Manual Creation:
1. **GET `/reels/scene-based`**
   - Creates unsaved reel with 3 empty built scenes
   - Renders form with empty fields

2. **POST `/reels/scene-based`** (user fills and submits)
   - Goes to `reels#create` action
   - Calls `ReelCreationService` with form data
   - Saves reel with scenes → triggers HeyGen generation

### Smart Planning Integration:
1. **GET `/reels/scene-based?smart_planning_data={...}`**
   - Creates unsaved reel with 3 built scenes
   - Preloads planning data (title, description, scene scripts)
   - Renders form with pre-populated fields

2. **POST `/reels/scene-based`** (user submits pre-filled form)
   - Same flow as manual creation
   - All planning data gets saved to database

## Code Changes Made

### Files Modified:
- `app/controllers/reels_controller.rb` - Fixed reel initialization and added preload methods
- `app/views/reels/scene_based.html.haml` - Removed explicit form URL
- `app/models/reel_scene.rb` - Added draft status validation bypass
- `app/services/heygen/generate_video_service.rb` - Fixed kling video type handling

### Key Methods:
- `ReelsController#new` - Restored unsaved reel pattern
- `ReelsController#preload_smart_planning_data` - Adapted for unsaved reels
- `ReelsController#preload_scenes_from_shotplan` - Use build instead of create
- `ReelScene#reel_is_draft?` - Allow nil fields for draft reels

## Testing Verification

### Manual Form Submission:
```bash
# Before fix: No POST request, empty reels created
# After fix: Proper POST to reels#create, reel with 3 scenes, HeyGen generation

User reels:
  Status: completed, Scenes: 3  ✅
  Status: draft, Scenes: 0      ❌ (old broken reels)
```

### Smart Planning Integration:
```bash
# Logs show successful preload:
🎯 Preloading smart planning data: ["title", "description", "shotplan"]
🎬 Found 3 scenes to preload
✅ Built scene 1 successfully
🎉 Smart planning preload completed
```

## Prevention Measures

### 1. Always Use Unsaved Models for Forms
```ruby
# ✅ Correct - form will POST to create
@resource = current_user.resources.build(params)

# ❌ Wrong - form will PATCH to update
@resource = current_user.resources.create(params)
```

### 2. Test Form Behavior After Model Changes
- Verify HTTP method (POST vs PATCH) in browser network tab
- Check form action URL in rendered HTML
- Ensure controller receives expected params

### 3. Understand form_with Behavior
```ruby
# form_with detects record state:
record.new_record?  # → POST to create
record.persisted?   # → PATCH to update
```

## Related Issues Fixed

While debugging, also discovered and fixed:
1. **Missing API tokens** - Some users don't have HeyGen tokens configured
2. **Validation bypass** - ReelScene validations needed draft status exceptions
3. **Kling video type** - Test expected different payload structure

## Lessons Learned

1. **Form state matters** - Always check if models are saved/unsaved when using form helpers
2. **Service abstractions** - InitializationService hid the critical save operation
3. **Route constraints** - PATCH routes need to exist if forms generate PATCH requests
4. **Testing gaps** - Integration tests would have caught this form submission failure
5. **Refactor carefully** - Changing controller initialization patterns can break fundamental workflows

---

**Issue Resolution Time**: ~4 hours of debugging
**Root Cause**: Saved reel during GET request changed form behavior from POST to PATCH
**Impact**: Complete feature breakage - no reels could be created via web interface
**Severity**: Critical - core functionality completely broken