fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios show_help

```sh
[bundle exec] fastlane ios show_help
```

Show available lanes and their descriptions

### ios build_ios

```sh
[bundle exec] fastlane ios build_ios
```

Build iOS app for simulator

### ios build_macos

```sh
[bundle exec] fastlane ios build_macos
```

Build macOS app (Mac Catalyst)

### ios build_all

```sh
[bundle exec] fastlane ios build_all
```

Build both iOS and macOS apps

### ios test_ios

```sh
[bundle exec] fastlane ios test_ios
```

Run iOS tests

### ios test_macos

```sh
[bundle exec] fastlane ios test_macos
```

Run macOS tests

### ios test_all

```sh
[bundle exec] fastlane ios test_all
```

Run tests on all platforms

### ios clean

```sh
[bundle exec] fastlane ios clean
```

Clean build artifacts

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
