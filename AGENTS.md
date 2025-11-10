# Repository Guidelines

## Project Structure & Module Organization
- `HslWidget/Api` hosts Digitransit-facing clients (`HslApi.swift`) plus request helpers; keep new endpoints here.
- `HslWidget/Model` defines immutable Swift structs for stops, departures, and widget timelines.
- `HslWidget` root contains SwiftUI entry points (`HslWidgetApp.swift`, `StopSelectionView.swift`) and shared assets under `Assets.xcassets`.
- `stopInfo` is the widget extension target; mirror shared code via target membership rather than duplication.
- Previews and sample payloads live in `HslWidget/Preview Content`; refresh them whenever APIs change so design reviews stay accurate.

## Build, Test & Development Commands
- `xcodebuild -scheme HslWidget -configuration Debug build` compiles the main app.
- `xcodebuild -scheme stopInfo -destination 'platform=iOS Simulator,name=iPhone 15' build` validates the widget extension in CI-friendly form.
- `xcodebuild test -scheme HslWidget -destination 'platform=iOS Simulator,name=iPhone 15'` runs XCTest bundles when present.
- `xed .` opens the workspace in Xcode; prefer running widgets via the `stopInfo` scheme to preview timelines.

## Coding Style & Naming Conventions
- Swift 5.9, 4-space indentation, and trailing commas where multi-line literals gain clarity.
- Prefer `struct` + `let` for models; use `enum ApiRoute` for fixed cases rather than raw strings.
- Async code should expose `async` functions that deliver `Result` types to the widget timeline; document public methods with triple-slash comments when behavior is non-obvious.
- Name assets and JSON fixtures with `PascalCase-Descriptor` (e.g., `AppIcon-1024.png`) to match current catalog patterns.

## Testing Guidelines
- Add unit tests under `HslWidgetTests/` mirroring the module hierarchy (e.g., `Api/HslApiTests.swift`).
- Use XCTest with descriptive method names (`testFetchStopsReturnsNearestStop()`); cover parsing logic and widget timeline snapshots.
- Snapshot tests for SwiftUI views belong in a `SnapshotTests` group; store reference images under `Tests/ReferenceImages`.
- Aim to guard every Digitransit contract with at least one test that exercises fallback behavior for missing fields.

## Commit & Pull Request Workflow
- Follow the existing imperative, sentence-case commit style (`Add application icon`, `Update to latest digitransit API`); keep subject ≤ 72 chars.
- Each PR should link an issue or describe the rider-facing change, list test commands run, and attach updated widget screenshots when UI changes occur.
- Avoid mixing API key or secret updates with feature commits; handle credentials via configuration only.

## Security & Configuration Tips
- Never commit Digitransit API keys; store them in Xcode `xcconfig` files excluded from git or in the keychain.
- Rotate keys immediately if exposed (see recent history); scrub history with `git filter-repo` before force-pushing.
- Validate entitlements (`HslWidget.entitlements`, `stopInfoExtension.entitlements`) after capability changes so the widget stays signed correctly.
