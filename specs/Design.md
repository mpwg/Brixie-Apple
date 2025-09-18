# Brixie Technical Design

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                         BrixieApp                            │
│  ┌─────────────────────────────────────────────────────┐    │
│  │                    SwiftUI Views                     │    │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────────────┐  │    │
│  │  │ ListView │  │SearchView│  │ SetDetailView    │  │    │
│  │  └──────────┘  └──────────┘  └──────────────────┘  │    │
│  └─────────────────────────────────────────────────────┘    │
│                              │                               │
│  ┌─────────────────────────────────────────────────────┐    │
│  │                     ViewModels                       │    │
│  │  ┌────────────┐  ┌────────────┐  ┌─────────────┐  │    │
│  │  │SetListVM   │  │SearchVM    │  │SetDetailVM  │  │    │
│  │  └────────────┘  └────────────┘  └─────────────┘  │    │
│  └─────────────────────────────────────────────────────┘    │
│                              │                               │
│  ┌─────────────────────────────────────────────────────┐    │
│  │                      Services                        │    │
│  │  ┌──────────────┐  ┌───────────────┐  ┌─────────┐  │    │
│  │  │LegoSetService│  │ImageCache     │  │ThemesMgr│  │    │
│  │  └──────────────┘  └───────────────┘  └─────────┘  │    │
│  └─────────────────────────────────────────────────────┘    │
│                              │                               │
│  ┌─────────────────────────────────────────────────────┐    │
│  │              Data Layer (SwiftData)                  │    │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────────────┐  │    │
│  │  │LegoSet   │  │Theme     │  │UserCollection    │  │    │
│  │  └──────────┘  └──────────┘  └──────────────────┘  │    │
│  └─────────────────────────────────────────────────────┘    │
│                              │                               │
│  ┌─────────────────────────────────────────────────────┐    │
│  │           External (RebrickableLegoAPIClient)        │    │
│  └─────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

## Data Models

### LegoSet Model
```swift
@Model
final class LegoSet {
    @Attribute(.unique) var setNumber: String
    var name: String
    var year: Int
    var themeId: Int
    var numParts: Int
    var setImageURL: String?
    var lastModified: Date
    
    // Relationships
    var theme: Theme?
    var userCollection: UserCollection?
}
```

### Theme Model
```swift
@Model
final class Theme {
    @Attribute(.unique) var id: Int
    var name: String
    var parentId: Int?
    
    // Relationships
    var sets: [LegoSet]
    var subthemes: [Theme]
}
```

### UserCollection Model
```swift
@Model
final class UserCollection {
    var id: UUID
    var isOwned: Bool
    var isWishlist: Bool
    var hasMissingParts: Bool
    var isSealedBox: Bool
    var dateAdded: Date
    
    // Relationship
    var legoSet: LegoSet
}
```

## View Components

### Main Navigation Structure
- **ContentView**: Root container with tab/sidebar navigation
- **SetListView**: Browse all sets with theme filtering
- **SearchView**: Search interface with multiple search modes
- **SetDetailView**: Detailed set information
- **CollectionView**: User's collection management
- **SettingsView**: App configuration and API key

### Reusable Components
- **AsyncCachedImage**: Image loading with cache
- **SetCardView**: Set thumbnail display
- **ThemeNavigator**: Hierarchical theme browser
- **EmptyStateView**: No data states
- **LoadingView**: Loading indicators

## Service Layer

### LegoSetService
- Fetches sets from Rebrickable API
- Manages local SwiftData cache
- Handles pagination
- Provides search functionality

### ImageCacheService
- NSCache for memory caching
- File system cache in Documents/ImageCache
- 50MB size limit management
- Async image downloading

### ThemeManager
- Theme hierarchy management
- Theme filtering
- Theme search

## Implementation Strategy

### Phase 1: Core Infrastructure
1. Set up SwiftData models
2. Implement API client configuration
3. Create basic navigation structure
4. Implement image caching service

### Phase 2: Browse & Display
1. Implement set list view
2. Create theme navigation
3. Add set detail view
4. Implement image loading

### Phase 3: Search & Filter
1. Add search interface
2. Implement search by number
3. Add barcode scanning
4. Create filter options

### Phase 4: Collection Management
1. Add collection tracking
2. Implement wishlist
3. Add missing parts tracking
4. Create statistics view

### Phase 5: Polish & Optimization
1. Add animations
2. Implement offline support
3. Optimize performance
4. Add accessibility features