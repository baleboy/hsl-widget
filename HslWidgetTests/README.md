# HSL Widget Tests

## Setup Instructions

Since this project doesn't have a test target yet, follow these steps to add one:

### 1. Add Test Target in Xcode

1. Open the project in Xcode: `xed .`
2. Click on the project in the navigator (top-level "HslWidget")
3. At the bottom of the targets list, click the "+" button
4. Select "Unit Testing Bundle" (not UI Testing)
5. Name it: `HslWidgetTests`
6. Set Product Name: `HslWidgetTests`
7. Set Team: (your development team)
8. Set Target to be Tested: `HslWidget`
9. Click "Finish"

### 2. Configure Test Target

After creating the test target:

1. Select the `HslWidgetTests` target
2. Go to "Build Phases" tab
3. In "Link Binary With Libraries", add:
   - `WidgetKit.framework`
   - `XCTest.framework` (should already be there)
4. In "Compile Sources", ensure `SmokeTests.swift` is included
5. Go to "Build Settings" tab
6. Search for "Test Host" and ensure it points to: `$(BUILT_PRODUCTS_DIR)/HslWidget.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/HslWidget`

### 3. Add Shared Code to Test Target

The tests need access to your app code. For each file you want to test:

1. Select the file in the Project Navigator (e.g., `Stop.swift`, `HslApi.swift`, etc.)
2. Open the File Inspector (right panel)
3. Under "Target Membership", check the box for `HslWidgetTests`

**Files to add to test target:**
- `HslWidget/Model/Stop.swift`
- `HslWidget/Model/Departure.swift`
- `HslWidget/Model/FavoritesManager.swift`
- `HslWidget/Api/HslApi.swift`
- `stopInfo/stopInfo.swift` (for Provider)

### 4. Alternative: Use @testable import

Instead of adding files to the test target, you can use `@testable import`:

1. In your app target's Build Settings, ensure "Enable Testability" is set to "Yes" for Debug configuration
2. The test file already uses `@testable import HslWidget` and `@testable import stopInfo`

## Running Tests

### From Command Line

```bash
# Run all tests
xcodebuild test -scheme stopInfoExtension -destination 'platform=iOS Simulator,name=iPhone 16'

# Run specific test
xcodebuild test -scheme stopInfoExtension -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:HslWidgetTests/SmokeTests/testAPIKeyIsConfigured
```

### From Xcode

1. Open the project: `xed .`
2. Select `stopInfoExtension` scheme
3. Press `Cmd+U` to run all tests
4. Or click the diamond icon next to individual test methods to run one test

### In CI/CD

Add this to your CI workflow:

```yaml
- name: Run tests
  run: xcodebuild test -scheme stopInfoExtension -destination 'platform=iOS Simulator,name=iPhone 16'
```

## What the Smoke Tests Cover

The `SmokeTests.swift` file includes tests for:

1. **API Key Configuration** - Catches missing API key before deployment
2. **App Group Setup** - Verifies shared UserDefaults is accessible
3. **Model Creation** - Basic sanity checks for Stop and Departure
4. **Codable Support** - Critical for favorites persistence
5. **Widget Provider** - Ensures placeholder/snapshot don't crash
6. **Manager Singletons** - Verify FavoritesManager and HslApi work
7. **Filter Logic** - Tests line and headsign filtering

## Expected Results

All tests should pass if:
- ✅ `Config.xcconfig` has `HSL_API_KEY` set
- ✅ App Group entitlement is configured
- ✅ No critical crashes in basic initialization

If `testAPIKeyIsConfigured` fails, check that:
1. `Config.xcconfig` exists and contains `HSL_API_KEY = <your-key>`
2. `Info.plist` references `$(HSL_API_KEY)` for the key
3. The test target has access to the Info.plist

## Next Steps

After this basic smoke test works, you can expand with:
- API response parsing tests (with mock JSON)
- Timeline generation logic tests
- FavoritesManager integration tests
- Snapshot tests for widget views

See the full test strategy discussion for the complete plan.
