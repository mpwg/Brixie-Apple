# Accessibility & Dynamic Type Implementation Guide

## Overview
This document outlines the accessibility and dynamic type improvements implemented in Brixie to ensure the app is inclusive and usable for all users, including those with disabilities.

## Dynamic Type Support

### Typography Updates
- **Before**: Fixed font sizes (e.g., `Font.system(size: 28, weight: .bold)`)
- **After**: System text styles that scale (e.g., `Font.system(.largeTitle, design: .rounded, weight: .bold)`)

### Responsive Sizing
- Added `BrixieScaledMetrics` with `@ScaledMetric` properties for:
  - Card padding: 20pt (scales with user preferences)
  - Button padding: 24pt (scales with user preferences)
  - Icon size: 20pt (scales with user preferences)
  - Corner radius: 16pt (scales with user preferences)
  - Shadow radius: 12pt (scales with user preferences)

## Accessibility Improvements

### Helper Functions
- `brixieAccessibility(label:hint:traits:)`: Consistent accessibility labeling
- `brixieImageAccessibility(label:isDecorative:)`: Proper image accessibility handling

### Component Enhancements

#### TabView (ContentView)
- **Labels**: Descriptive tab names
- **Hints**: Clear descriptions of tab content and actions
- **Traits**: Proper button traits for navigation

#### SetRowView
- **Image accessibility**: Descriptive labels for LEGO set images
- **Combined accessibility**: Row-level accessibility with complete set information
- **Favorite button**: Clear toggle action descriptions

#### FavoriteButton Component
- **New dedicated component** with built-in accessibility
- **State-aware labels**: Different labels for favorited vs non-favorited states
- **Action hints**: Clear descriptions of what will happen on tap

#### RangeSlider
- **Handle accessibility**: Individual labels for min/max handles
- **Adjustable trait**: Proper VoiceOver interaction
- **Value announcements**: Current range values spoken to users

#### Search Interface
- **Recent searches**: Descriptive labels and action hints
- **Search suggestions**: Proper button traits and descriptions

#### Categories
- **Category rows**: Combined accessibility with name and set count
- **Sort menu**: Current sort state information
- **Icons**: Descriptive labels for category icons

#### Settings
- **Theme selection**: State-aware accessibility (selected vs unselected)
- **Cache management**: Warning descriptions for destructive actions
- **Clear action hints**: Specific information about what will be cleared

### Loading States
- **Loading indicators**: `updatesFrequently` trait for dynamic content
- **Progress announcements**: Clear status communication

## Testing Recommendations

### VoiceOver Testing
1. Enable VoiceOver in iOS Settings > Accessibility > VoiceOver
2. Navigate through each screen using swipe gestures
3. Verify all interactive elements are properly labeled
4. Test that hints provide meaningful action descriptions

### Dynamic Type Testing
1. Go to Settings > Display & Brightness > Text Size
2. Test with various text sizes including accessibility sizes
3. Verify layouts don't break with large text
4. Ensure important content remains accessible

### Expected Behaviors
- **Navigation**: All tabs and buttons should have clear, descriptive labels
- **Content**: Set information should be announced in a logical order
- **Actions**: Button purposes should be clearly communicated
- **State**: Current selections and states should be announced
- **Feedback**: Loading states and changes should be communicated

## Accessibility Compliance

### WCAG 2.1 Guidelines Addressed
- **1.1.1 Non-text Content**: Images have appropriate alt text or are marked as decorative
- **1.3.1 Info and Relationships**: Proper use of accessibility traits and labels
- **2.1.1 Keyboard**: All functionality accessible via VoiceOver navigation
- **2.4.4 Link Purpose**: Clear button and link descriptions
- **3.2.2 On Input**: Predictable behavior for all controls

### iOS Accessibility Features Supported
- **VoiceOver**: Full navigation and content reading
- **Dynamic Type**: Text scaling for readability
- **Switch Control**: All buttons properly labeled for external switch navigation
- **Voice Control**: Descriptive labels enable voice-based interaction

## Implementation Notes

### Minimal Impact Design
- All accessibility improvements maintain existing functionality
- No breaking changes to existing UI or user experience
- Progressive enhancement approach - improves experience without disrupting current users

### Consistency
- Centralized accessibility helpers ensure consistent implementation
- Reusable patterns across all components
- Standardized labeling conventions

### Performance
- Accessibility additions have minimal performance impact
- @ScaledMetric properties only recalculate when needed
- Efficient string localization for accessibility labels