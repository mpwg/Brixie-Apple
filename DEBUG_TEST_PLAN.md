# Theme Debug Test Plan

## Issue
User reports seeing only ~20 root themes instead of expected larger number.

## Enhanced Debug Features Added
1. **ThemeDebugView**: Real-time theme analysis tool
2. **Enhanced Logging**: Detailed API response analysis in ThemeService
3. **Debug Access**: Added debug tools to Settings view

## Testing Steps

### 1. Access Debug Tools
1. Launch Brixie app
2. Navigate to Settings
3. Look for "Debug Tools" section
4. Tap "Theme Debug View"

### 2. Analyze Current State
In ThemeDebugView, check:
- **Total Themes**: Total count in database
- **Root Themes**: Count where parentId == nil
- **Theme Hierarchy**: Tree structure display
- **Last Fetch**: When themes were last updated

### 3. Force Refresh API Data
1. Tap "Refresh Themes from API" button
2. Watch the logs in Xcode Console for:
   - API request details
   - Response analysis (count, next/previous fields)
   - Pagination progress
   - Root theme filtering warnings

### 4. Console Log Analysis
Look for these log patterns:
- `[ThemeService] API Response:` - Shows raw API data
- `[ThemeService] WARNING: Suspiciously low root theme count` - Triggers if <30 root themes
- `[Network] GET /api/v3/lego/themes/` - API request details
- Pagination loop progress messages

### 5. Expected Outcomes
- Should see more than 20 root themes after refresh
- Console logs will reveal if issue is:
  - API returning limited data
  - Pagination not working correctly
  - Local filtering too aggressive
  - Theme hierarchy issues

## Debug Enhancement Summary
- Added comprehensive API response logging
- Improved pagination with safety limits (max 100 pages)
- Enhanced root theme filtering with warnings
- Consistent API ordering by ID
- Real-time debug interface with refresh capability

## Next Steps After Testing
Based on debug results, implement targeted fix:
1. **API Issue**: Adjust API parameters or pagination logic
2. **Filtering Issue**: Modify getRootThemes() logic
3. **Data Issue**: Investigate theme parent/child relationships