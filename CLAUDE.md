# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

HSL Widget is an iOS lock screen widget that displays real-time departure times for Helsinki Region Transport (HSL) stops using the Finnish Digitransit GraphQL API. The project consists of a main app for stop selection and a widget extension that displays departure information.

## Build Commands

- Open in Xcode: `xed .`
- Build app and widget: `xcodebuild -scheme stopInfoExtension -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16' build`
- Run tests: `xcodebuild test -scheme stopInfoExtension -destination 'platform=iOS Simulator,name=iPhone 16'`

The project has a single scheme `stopInfoExtension` that builds both targets (main app and widget extension). For development, prefer running this scheme in Xcode to preview widget timelines.

## Architecture

### Target Structure
The project has two targets with distinct responsibilities:
- **HslWidget** (main app): Provides the stop selection UI where users search and choose their transit stop
- **stopInfo** (widget extension): Renders departure times on the lock screen and updates timelines

Shared code lives in `HslWidget/` and is included in the widget target via target membership (check Target Membership in Xcode's File Inspector).

### Data Flow
1. User selects a stop in `StopSelectionView` (main app)
2. Stop ID and name are saved to App Group shared UserDefaults (`group.balenet.widget`)
3. Widget extension reads the shared preferences in `Provider.getTimeline()`
4. `HslApi.fetchDepartures()` queries Digitransit GraphQL API
5. Widget creates multiple timeline entries - one for each departure window - so iOS can pre-render future states
6. When a departure passes, the widget automatically advances to the next timeline entry

### Timeline Strategy
The widget generates a timeline with multiple entries where each entry shows the next N departures (currently 2). Entry dates are staggered at each departure time so the widget updates naturally as buses/trams leave. The timeline policy is `.atEnd`, meaning the widget refreshes when the last entry expires.

### API Integration
All Digitransit API calls go through `HslApi.swift` which uses GraphQL POST requests. The API key is currently hardcoded but should be moved to an excluded xcconfig file or keychain. The API returns:
- All stops via `fetchAllStops()` (used for search in main app)
- Departure times via `fetchDepartures()` (used by widget to populate timelines)

Response models are in `Api/DepartureTimesQueryResponse.swift` and `Api/StopsQueryResponse.swift`, while domain models are in `Model/Stop.swift` and `Model/Departure.swift`.

## Key Files

- `stopInfo/stopInfo.swift:11-64` - Widget timeline provider; controls refresh logic and data fetching
- `HslWidget/Api/HslApi.swift:14-16` - API endpoint and key configuration (key should be externalized)
- `HslWidget/StopSelectionView.swift:64-68` - Triggers widget reload via `WidgetCenter.shared.reloadAllTimelines()`
- `HslWidget/Model/*` - Immutable structs for stops and departures

## Development Notes

- The widget uses `UserDefaults(suiteName: "group.balenet.widget")` for cross-target data sharing; ensure the App Group is configured in entitlements
- Preview data is hardcoded in `Provider.TimetableEntry.example` and fallback constants at the top of `stopInfo.swift`
- The API key placeholder "API_KEY_HERE" needs replacement with a valid Digitransit subscription key
- Widget supports `.accessoryRectangular` (lock screen) and `.systemSmall` (home screen) families
- If new files are needed, don't try to add them to the project yourself, it will be done manually using XCode. Just ask the user to add the new file. 

## Coding Style

When writing or modifying code in this project, follow these guidelines:

### Methods
- **Keep methods short**: Methods should ideally be ≤20 lines. If a method exceeds this, extract logical blocks into separate helper methods
- **Single Responsibility Principle**: Each method should do one thing well. Extract complex logic into well-named helper methods
- **Meaningful names**: Use descriptive method names that clearly indicate what the method does, making the code self-documenting

### Classes and Files
- **Keep classes focused**: Each class should have a single, well-defined purpose. If a class is doing too much, split it into multiple classes
- **Limit file length**: Class files should ideally be ≤200 lines. Long files indicate too many responsibilities
- **Extract related functionality**: Group related methods into separate helper classes, extensions, or utility types
- **Use composition over inheritance**: Prefer smaller, composable types over large monolithic classes
- **SwiftUI Views**: Break down complex views into smaller subviews. Each view component should be in its own file or clearly separated with `// MARK:` comments

### Modularization
- **Separate concerns**: Split UI, business logic, and data layers clearly
- **Reusable components**: Extract common patterns into shared utilities or extensions
- **Testability**: Smaller, focused classes and methods are easier to test
- Avoid duplicated code

When reviewing existing code, proactively suggest refactoring opportunities for long or complex methods and classes. Always check if a class file exceeds 200 lines and recommend splitting it.

## Commit Style

Follow existing imperative, sentence-case style with subjects ≤72 chars:
- `Add application icon`
- `Update to latest digitransit API`
- `Remove unnecessary data members from Stop`
