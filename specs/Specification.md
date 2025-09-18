# Brixie Requirements Specification

## User Stories

### Core Features

#### US-001: Browse LEGO Sets
WHEN the user opens the app, THE SYSTEM SHALL display a browseable list of LEGO sets from the Rebrickable API

#### US-002: Theme Navigation
WHEN the user selects a theme category, THE SYSTEM SHALL display all LEGO sets within that theme

#### US-003: Search Functionality
WHEN the user enters search criteria, THE SYSTEM SHALL filter and display matching LEGO sets by:
- Set number
- Set name
- Theme
- Barcode (via manual entry or camera scanning)

#### US-004: Set Details View
WHEN the user selects a LEGO set, THE SYSTEM SHALL display:
- Set images (cached locally)
- Set number and name
- Theme information
- Year of release
- Part count
- Retail price (if available)
- Build instructions link

#### US-005: Collection Management
WHEN authenticated, THE SYSTEM SHALL allow users to:
- Mark sets as owned ("Meine LEGO-Sammlung")
- Create a wishlist ("LEGO-Wunschliste")
- Track missing parts ("Fehlende Teile")
- Track sealed boxes ("Versiegelte Box")

#### US-006: Image Caching
WHEN displaying set images, THE SYSTEM SHALL:
- Download images on first view
- Cache images locally (50MB limit)
- Display cached images offline
- Use AsyncCachedImage component

#### US-007: Multi-Platform Support
THE SYSTEM SHALL provide native experiences for:
- iOS 26+ (iPhone and iPad)
- macOS 26+ (Mac Catalyst)
- visionOS 26+

### Data Requirements

#### DR-001: API Integration
THE SYSTEM SHALL integrate with Rebrickable API v3 using the RebrickableLegoAPIClient package

#### DR-002: Local Persistence
THE SYSTEM SHALL use SwiftData for:
- Cached set data
- User collections
- Search history
- App preferences

#### DR-003: Offline Support
WHEN offline, THE SYSTEM SHALL display previously cached data and queue user actions for sync

### UI Requirements

#### UI-001: Navigation Structure
THE SYSTEM SHALL provide:
- Tab bar navigation (iOS/visionOS)
- Sidebar navigation (macOS/iPadOS)
- Search bar in navigation
- Theme hierarchy browser

#### UI-002: Visual Design
THE SYSTEM SHALL implement:
- Modern, clean interface following Apple HIG
- SF Symbols for icons
- Dynamic Type support
- Dark mode support
- Accessibility features (VoiceOver, Dynamic Type)

#### UI-003: Empty States
WHEN no data is available, THE SYSTEM SHALL display helpful empty states with:
- Descriptive message
- Action button (e.g., "Ich verstehe" / "I understand")
- Visual indicator

### Performance Requirements

#### PR-001: Image Loading
THE SYSTEM SHALL load and display images progressively with placeholders

#### PR-002: Search Performance
THE SYSTEM SHALL return search results within 500ms for local data

#### PR-003: Memory Management
THE SYSTEM SHALL maintain image cache under 50MB total size

### Security Requirements

#### SR-001: API Key Management
THE SYSTEM SHALL securely store the Rebrickable API key using @AppStorage

#### SR-002: Network Security
THE SYSTEM SHALL use HTTPS for all API communications