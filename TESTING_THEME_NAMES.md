# Testing Theme Name Population Feature

This document describes how to manually test the newly implemented theme name population functionality.

## Overview

The theme name population feature denormalizes theme names during set fetching and provides background backfill functionality for existing sets. Theme names are now displayed in the UI as green capsules next to the year information.

## Test Scenarios

### 1. Fresh App Installation (Theme Names from Remote)

**Steps:**
1. Fresh install of the app or clear all data
2. Configure Rebrickable API key in Settings
3. Navigate to the Sets list
4. Observe that sets display theme names as green capsules

**Expected Result:**
- Sets should load with theme names populated automatically
- Theme names appear as green capsules in the set list
- Set detail view shows theme name in the info section

### 2. Existing Data Backfill

**Steps:**
1. Have existing sets in the app without theme names
2. Ensure themes are cached (browse themes or fetch new sets)
3. Call the backfill functionality (via SetsListViewModel.backfillThemeNames())
4. Refresh the sets list

**Expected Result:**
- Previously cached sets without theme names should now display theme names
- UI updates to show the green theme name capsules

### 3. Network Offline Behavior

**Steps:**
1. Enable airplane mode or disconnect network
2. Browse cached sets
3. Verify theme names are still displayed

**Expected Result:**
- Cached sets should retain their theme names
- No network calls should affect theme name display for cached sets

### 4. Missing Theme Handling

**Steps:**
1. Load sets that reference theme IDs not in the cache
2. Observe the behavior

**Expected Result:**
- Sets with missing themes should display without theme names (no green capsule)
- App should not crash or show errors
- Other set information should display normally

## UI Verification Points

### Set List View
- [ ] Theme names appear as green capsules
- [ ] Theme capsules are positioned between year and piece count
- [ ] Sets without theme names don't show empty capsules
- [ ] Theme names are readable and properly truncated if too long

### Set Detail View
- [ ] Theme names appear in the info section
- [ ] Theme field is only shown when theme name is available
- [ ] Theme name matches what's shown in the list view

## Developer Testing

### Unit Tests
Run the test suite to verify functionality:
```bash
xcodebuild test -project Brixie.xcodeproj -scheme Brixie -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:BrixieTests/ThemeNamePopulationTests
```

### Test Cases Covered
- `testLegoSetInitializerWithThemeName`: Verifies LegoSet can be created with theme names
- `testLegoSetInitializerWithoutThemeName`: Ensures backward compatibility
- `testThemeNamePopulationWithCachedThemes`: Tests theme name lookup from cache
- `testThemeNamePopulationWithMissingTheme`: Handles missing themes gracefully
- `testBackfillThemeNames`: Verifies backfill functionality

## Implementation Details

### Key Components Modified
- **LegoSet Model**: Enhanced initializer to accept `themeName` parameter
- **LegoSetRepositoryImpl**: Added theme name population logic
- **SetsListView**: Added theme name display as green capsules
- **SetsListViewModel**: Added backfill method

### Performance Considerations
- Theme name lookup uses O(1) dictionary lookup
- Backfill only processes sets without theme names
- UI updates are batched and efficient

## Troubleshooting

### Theme Names Not Appearing
1. Verify API key is configured correctly
2. Check that themes are being fetched and cached
3. Ensure network connectivity for initial theme fetch
4. Verify theme IDs in sets match cached theme IDs

### Performance Issues
1. Check if too many sets are being processed at once
2. Verify theme cache is not excessively large
3. Monitor memory usage during backfill operations

### UI Display Issues
1. Verify theme names are not too long (causing layout issues)
2. Check that color contrast is adequate for accessibility
3. Test on different screen sizes and orientations