# Branching Strategy for Brixie

## Overview

This document defines the branching strategy for the Brixie iOS/macOS application. The strategy is designed to support continuous development, feature isolation, and stable releases while maintaining code quality through automated CI/CD pipelines.

## Branch Types

### Main Branches

#### `main`
- **Purpose**: Production-ready code
- **Protection**: Protected branch with required reviews and CI checks
- **Deployment**: Automatically deploys to App Store Connect (when CI/CD is configured)
- **Lifetime**: Permanent
- **Merge Strategy**: Squash and merge from `develop` only

#### `develop`
- **Purpose**: Integration branch for ongoing development
- **Protection**: Protected with required CI checks
- **Deployment**: Automatically deploys to TestFlight beta (when CI/CD is configured)
- **Lifetime**: Permanent
- **Merge Strategy**: Merge commits from feature branches

### Supporting Branches

#### Feature Branches
- **Naming**: `feature/description` or `feature/issue-number-description`
- **Purpose**: Develop new features or enhancements
- **Base**: `develop`
- **Merge Target**: `develop`
- **Examples**:
  - `feature/lego-set-search`
  - `feature/image-caching`
  - `feature/detailed-set-view`

#### Bugfix Branches
- **Naming**: `bugfix/description` or `bugfix/issue-number-description`
- **Purpose**: Fix non-critical bugs
- **Base**: `develop`
- **Merge Target**: `develop`
- **Examples**:
  - `bugfix/search-crash-ios`
  - `bugfix/image-loading-macos`

#### Hotfix Branches
- **Naming**: `hotfix/description` or `hotfix/version-number`
- **Purpose**: Critical fixes for production issues
- **Base**: `main`
- **Merge Target**: Both `main` and `develop`
- **Examples**:
  - `hotfix/critical-crash-fix`
  - `hotfix/1.0.1`

#### Release Branches
- **Naming**: `release/version-number`
- **Purpose**: Prepare releases, final testing, and minor fixes
- **Base**: `develop`
- **Merge Target**: Both `main` and `develop`
- **Examples**:
  - `release/1.0.0`
  - `release/1.1.0`

#### Chore/Maintenance Branches
- **Naming**: `chore/description`
- **Purpose**: Build system, CI/CD, documentation, dependencies
- **Base**: `develop`
- **Merge Target**: `develop`
- **Examples**:
  - `chore/update-fastlane`
  - `chore/ci-improvements`

## Workflow

### Feature Development

1. Create feature branch from `develop`
   ```bash
   git checkout develop
   git pull origin develop
   git checkout -b feature/my-feature
   ```

2. Develop and commit changes
   ```bash
   git add .
   git commit -m "Add feature implementation"
   ```

3. Push and create Pull Request
   ```bash
   git push origin feature/my-feature
   ```

4. Create PR targeting `develop` with:
   - Clear description
   - Required CI checks passing (iOS and macOS builds)
   - Code review approval

5. Merge using "Squash and merge"

### Release Process

1. Create release branch from `develop`
   ```bash
   git checkout develop
   git pull origin develop
   git checkout -b release/1.0.0
   ```

2. Update version numbers and finalize release
   ```bash
   # Update version in project files
   git commit -m "Bump version to 1.0.0"
   ```

3. Create PRs:
   - `release/1.0.0` → `main` (for production release)
   - `release/1.0.0` → `develop` (to sync any release fixes)

4. Tag the release on `main`
   ```bash
   git tag -a v1.0.0 -m "Release version 1.0.0"
   git push origin v1.0.0
   ```

### Hotfix Process

1. Create hotfix branch from `main`
   ```bash
   git checkout main
   git pull origin main
   git checkout -b hotfix/critical-fix
   ```

2. Fix the issue and commit
   ```bash
   git commit -m "Fix critical production issue"
   ```

3. Create PRs for both branches:
   - `hotfix/critical-fix` → `main`
   - `hotfix/critical-fix` → `develop`

## CI/CD Requirements

### Branch Protection Rules

#### `main` branch:
- Require pull request reviews (minimum 1)
- Require status checks:
  - iOS build (fastlane ios build_ios)
  - macOS build (fastlane ios build_macos)
  - iOS tests (fastlane ios test_ios)
  - macOS tests (fastlane ios test_macos)
- Require branches to be up to date
- Restrict pushes to admins only

#### `develop` branch:
- Require status checks:
  - iOS build
  - macOS build
  - iOS tests
  - macOS tests
- Allow force pushes for maintainers

### Required Status Checks

All PRs must pass these checks before merging:

```bash
# iOS build check
REBRICKABLE_API_KEY="test_key" fastlane ios build_ios

# macOS build check
REBRICKABLE_API_KEY="test_key" fastlane ios build_macos

# iOS tests
REBRICKABLE_API_KEY="test_key" fastlane ios test_ios

# macOS tests
REBRICKABLE_API_KEY="test_key" fastlane ios test_macos
```

## Branch Naming Conventions

### Allowed Prefixes
- `feature/` - New features
- `bugfix/` - Bug fixes
- `hotfix/` - Critical production fixes
- `release/` - Release preparation
- `chore/` - Maintenance tasks
- `docs/` - Documentation updates
- `refactor/` - Code refactoring

### Naming Rules
- Use lowercase with hyphens
- Be descriptive but concise
- Include issue number when applicable
- Examples:
  - ✅ `feature/lego-set-search`
  - ✅ `bugfix/123-image-cache-crash`
  - ✅ `chore/update-dependencies`
  - ❌ `fix_bug`
  - ❌ `Feature/LegoSets`

## Best Practices

### Commit Messages
- Use conventional commit format when possible
- Be clear and descriptive
- Examples:
  - `feat: add LEGO set search functionality`
  - `fix: resolve image caching crash on iOS`
  - `chore: update Fastlane configuration`

### Pull Requests
- Use descriptive titles
- Include testing instructions
- Reference related issues
- Ensure CI checks pass before requesting review
- Keep PRs focused and reasonably sized

### Code Quality
- All code must compile for both iOS and macOS
- Include appropriate tests
- Follow SwiftUI and SwiftData best practices
- Maintain consistent code style

## Emergency Procedures

### Critical Production Issue
1. Create hotfix branch from `main`
2. Fix issue with minimal changes
3. Test thoroughly on both platforms
4. Create expedited PR with urgent review
5. Deploy immediately after merge
6. Back-merge to `develop`

### Rollback Process
1. Revert problematic commit on `main`
2. Create new release tag
3. Deploy reverted version
4. Fix issue properly in feature branch
5. Follow normal release process

## Branch Cleanup

### Automated Cleanup
- Delete merged feature branches automatically
- Keep release and hotfix branches for reference
- Archive branches older than 6 months

### Manual Cleanup
```bash
# Delete merged local branches
git branch --merged develop | grep -v -E "(develop|main|master)" | xargs -n 1 git branch -d

# Delete remote tracking branches
git remote prune origin
```

This branching strategy ensures stable releases, supports parallel development, and maintains high code quality through automated testing on both iOS and macOS platforms.