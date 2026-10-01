# Asset Pipeline Cache Troubleshooting

**Date**: December 10, 2025
**Issue**: JavaScript changes not reflecting in browser
**Root Cause**: Bundled assets with cache hashing + browser cache

---

## 🐛 Problem Description

### Symptoms
- Code changes in `app/javascript/*.js` don't appear in browser
- Browser console shows old JavaScript code
- Even hard refresh doesn't load new code
- Incognito mode also shows old code

### Root Cause
When JavaScript files are bundled into `application.js`:
1. esbuild creates `application.js` with content hash (e.g., `application-496ac3c8.js`)
2. Sprockets/Propshaft may serve old precompiled versions from `public/assets/`
3. Browser caches the bundled file by hash
4. Changes to individual files (`planning_details.js`) don't trigger bundle regeneration

---

## ✅ Solution

### Quick Fix - Use the dev-rebuild script

```bash
# Stop Rails server (Ctrl+C)

# Run the rebuild script
./bin/dev-rebuild

# Restart Rails server
rails server

# Hard refresh browser
Ctrl + Shift + R
```

### Manual Steps

If the script doesn't work, follow these steps:

```bash
# 1. Stop Rails server
# Ctrl+C

# 2. Clean ALL caches
rm -rf public/assets/*
rm -rf tmp/cache/*
rm -rf app/assets/builds/*

# 3. Rebuild JavaScript
npm run build

# 4. Rebuild CSS (if needed)
npm run build:css

# 5. Verify generated files
ls -lh app/assets/builds/

# 6. Check the bundled code contains your changes
grep "your_function_name" app/assets/builds/application.js

# 7. Restart Rails server
rails server

# 8. Hard refresh browser
# Chrome: Ctrl + Shift + R
# Or: DevTools → Right-click refresh → "Empty Cache and Hard Reload"
```

---

## 🔍 Debugging Steps

### 1. Verify Source File
```bash
# Check your changes are in the source file
cat app/javascript/your_file.js
```

### 2. Verify Build Output
```bash
# Check the bundled file includes your changes
grep "your_code_marker" app/assets/builds/application.js
```

### 3. Check What Browser is Loading
1. Open DevTools (F12)
2. Go to **Network** tab
3. Filter by "JS"
4. Refresh page
5. Click on `application-*.js`
6. Check the **Response** tab
7. Search for your code

### 4. Verify No Precompiled Assets
```bash
# Should be empty in development
ls public/assets/
```

### 5. Check Rails Logs
When you load the page, Rails logs should show:
```
Started GET "/assets/application-[HASH].js"
Served asset /application-[HASH].js
```

The hash should be NEW after rebuild.

---

## 🚫 Common Mistakes

### ❌ Only rebuilding individual file
```bash
# This creates planning_details.js but doesn't update application.js bundle
npm run build  # Only runs esbuild on individual files
```

### ❌ Not clearing public/assets
```bash
# Sprockets may serve old precompiled files from here
public/assets/application-OLD_HASH.js  # ← This gets served instead
```

### ❌ Not restarting Rails server
```bash
# Rails caches asset paths in memory
# Must restart after cleaning assets
```

### ❌ Soft browser refresh
```bash
# F5 or Ctrl+R may use cached JS
# Must use Ctrl+Shift+R (hard refresh)
```

---

## 🛠️ Prevention

### Development Workflow

**Every time you change JavaScript:**

1. Stop server
2. Run `./bin/dev-rebuild`
3. Start server
4. Hard refresh browser

### Alternative: Watch Mode

Use separate terminals:

**Terminal 1 - Rails:**
```bash
rails server
```

**Terminal 2 - Asset watcher:**
```bash
npm run build -- --watch
```

**Important:** Even with watch mode, you need to:
- Clear `public/assets/` if it gets populated
- Hard refresh browser after changes

### Asset Configuration

Ensure your `config/environments/development.rb` has:

```ruby
# Compile assets on-the-fly
config.assets.compile = true

# Don't use cached compiled assets
config.assets.debug = true

# Disable asset caching in development
config.assets.digest = false  # Optional: removes hashes in dev
```

---

## 📋 Troubleshooting Checklist

When JavaScript changes don't appear:

- [ ] Changes saved in source file (`app/javascript/`)
- [ ] Ran `./bin/dev-rebuild` or manual steps
- [ ] Cleared `public/assets/` directory
- [ ] Cleared `tmp/cache/` directory
- [ ] Restarted Rails server
- [ ] Hard refresh browser (`Ctrl + Shift + R`)
- [ ] Tried incognito mode
- [ ] Verified new code in `app/assets/builds/application.js`
- [ ] Checked Network tab shows new asset hash

---

## 🔧 The dev-rebuild Script

Location: `bin/dev-rebuild`

**What it does:**
1. Cleans `public/assets/`
2. Cleans `tmp/cache/`
3. Cleans `app/assets/builds/`
4. Rebuilds JavaScript (`npm run build`)
5. Rebuilds CSS (`npm run build:css`)
6. Shows generated files

**Usage:**
```bash
./bin/dev-rebuild
```

**When to use:**
- After changing any JavaScript file
- After changing any CSS file
- When browser shows old code
- After pulling changes from git

---

## 📖 Understanding the Asset Pipeline

### File Flow in Development

```
Source File                    Bundle               Served To Browser
app/javascript/                app/assets/builds/   Browser cache
  planning_details.js    →→    application.js   →→  application-HASH.js
  (your changes)               (bundled)            (cached by hash)
```

### Why Caching Happens

1. **esbuild bundling**: Individual files → single `application.js`
2. **Content hashing**: `application.js` → `application-496ac3c8.js`
3. **Browser cache**: Hash unchanged → uses cached version
4. **Sprockets cache**: May serve old precompiled files

### The Cache Chain

```
Change file → Need rebuild → Need new hash → Need server restart → Need browser refresh
     ↓             ↓              ↓                ↓                    ↓
  (saved)     (npm build)    (new bundle)    (load new path)    (download new)
```

**Break at ANY step** = old code persists

---

## 🚀 Production Deployment

In production, precompiling is normal and desired:

```bash
# Production precompile
RAILS_ENV=production rails assets:precompile

# This creates public/assets/ with fingerprinted files
# Browser caches these long-term (good for performance)
```

**In development:** Keep `public/assets/` empty

---

## 📚 Related Documentation

- esbuild configuration: `package.json` → scripts.build
- Asset configuration: `config/environments/development.rb`
- Rails Asset Pipeline: https://guides.rubyonrails.org/asset_pipeline.html

---

## 🔗 Related Issues

- Content Structure Display Issue (December 2025)
- Rails-First Architecture Refactoring

---

**Last Updated**: December 10, 2025
**Status**: ✅ Resolved with dev-rebuild script
