# HSL Widget

[![Unit Tests](https://github.com/baleboy/hsl-widget/actions/workflows/test.yml/badge.svg)](https://github.com/baleboy/hsl-widget/actions/workflows/test.yml)
[![TestFlight](https://github.com/baleboy/hsl-widget/actions/workflows/testflight.yml/badge.svg)](https://github.com/baleboy/hsl-widget/actions/workflows/testflight.yml)

An iOS lock screen widget that displays real-time departure times for Helsinki Region Transport (HSL) stops. Never miss your bus or tram again with departure information right on your lock screen.

## Features

- **Real-time departures**: Shows live departure times for your selected transit stop
- **Lock screen widget**: Glanceable information without unlocking your phone
- **Home screen support**: Also available as a home screen widget
- **Auto-updating**: Widget automatically refreshes as departures pass
- **Stop search**: Easy-to-use search interface to find your stop
- **Multiple routes**: Displays upcoming departures for all routes at the selected stop

## Requirements

- iOS 16.0 or later (for lock screen widgets)
- Xcode 14.0 or later
- A valid [Digitransit API subscription key](https://digitransit.fi/en/developers/api-registration/)

## Installation

### Getting the API Key

1. Register for a Digitransit API subscription key at https://digitransit.fi/en/developers/api-registration/
2. Create a `Config.xcconfig` file in the project root (this file is gitignored):
   ```
   DIGITRANSIT_API_KEY = your-api-key-here
   ```
3. The API key will be automatically loaded from the config file

### Building the Project

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/hsl-widget.git
   cd hsl-widget
   ```

2. Open the project in Xcode:
   ```bash
   xed .
   ```

3. Build using Xcode (⌘+B) or via command line:
   ```bash
   xcodebuild -scheme stopInfoExtension -configuration Debug \
     -destination 'platform=iOS Simulator,name=iPhone 16' build
   ```

### Running Tests

The project includes 57 unit tests covering:
- API response parsing and error handling
- Favorites management and persistence
- Stop filtering logic (line filters, headsign patterns)
- Timeline building logic
- Model encoding/decoding

Run the test suite via Xcode (⌘+U) or command line:
```bash
xcodebuild test -scheme stopInfoExtension \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

Tests automatically run on every push to `main` and on pull requests via GitHub Actions. The TestFlight deployment will only proceed if all tests pass.

## Usage

### Setting Up Your Widget

1. **Launch the app** and search for your transit stop using the search bar
2. **Select your stop** from the search results
3. **Add the widget** to your lock screen:
   - Long-press your lock screen
   - Tap "Customize"
   - Select the lock screen area where you want the widget
   - Find "HSL Widget" in the widget list
   - Tap to add it

### Widget Behavior

- The widget shows the next 2 departures for your selected stop
- Departure times are shown in minutes (e.g., "5 min")
- The widget automatically updates as departures pass
- Tap the widget to open the app and change your stop

## Architecture

The project consists of two main targets:

### Main App (`HslWidget`)
- Provides the stop selection interface
- Handles stop search and selection
- Saves selected stop to shared App Group storage

### Widget Extension (`stopInfo`)
- Renders departure times on lock and home screens
- Fetches real-time data from Digitransit GraphQL API
- Manages timeline entries for automatic updates

### Data Flow

1. User selects a stop in the main app
2. Stop ID and name are saved to App Group shared UserDefaults (`group.balenet.widget`)
3. Widget extension reads the shared preferences
4. `HslApi.fetchDepartures()` queries the Digitransit GraphQL API
5. Widget creates timeline entries for each departure window
6. iOS automatically updates the widget as time passes

### Key Components

- **`stopInfo/stopInfo.swift`**: Widget timeline provider and refresh logic
- **`HslWidget/Api/HslApi.swift`**: Digitransit API integration
- **`HslWidget/StopSelectionView.swift`**: Main app UI for stop selection
- **`HslWidget/Model/`**: Domain models (Stop, Departure)

## Development

### Project Structure

```
hsl-widget/
├── HslWidget/              # Main app target
│   ├── Api/               # API client and response models
│   ├── Model/             # Domain models
│   └── StopSelectionView.swift  # Main UI
├── stopInfo/              # Widget extension target
│   └── stopInfo.swift     # Widget timeline provider
└── Config.xcconfig        # API key configuration (gitignored)
```

### Shared Code

Code in `HslWidget/` is shared between targets via Target Membership. Check the File Inspector in Xcode to verify which targets include each file.

### Timeline Strategy

The widget uses a multi-entry timeline where each entry represents a different departure window. Entries are staggered at each departure time, allowing the widget to automatically advance as departures pass. The timeline policy is `.atEnd`, triggering a refresh when all entries expire.

### App Group

The project uses App Group `group.balenet.widget` for sharing data between the main app and widget extension. Ensure this is properly configured in both targets' entitlements.

## Contributing

Contributions are welcome! Please follow the existing commit style:
- Use imperative, sentence-case commit messages
- Keep subject lines ≤72 characters
- Examples: "Add application icon", "Update to latest digitransit API"

## Credits

Inspired by [HomeDashboard](https://github.com/endanke/HomeDashboard) by @endanke

## API

Uses the [Finnish Digitransit GraphQL API](https://digitransit.fi/en/developers/)

## License

MIT License

Copyright (c) 2025 Francesco Balestrieri 

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
