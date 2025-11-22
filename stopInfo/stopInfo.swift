//
//  stopInfo.swift
//  stopInfo
//
//  Created by Francesco Balestrieri on 5.5.2024.
//

import WidgetKit
import SwiftUI
import CoreLocation

struct Provider: TimelineProvider {

    static let numberOfFetchedResults = 20

    private let favoritesManager = FavoritesManager.shared
    private let locationManager = LocationManager.shared

    /// Read the number of departures to show from settings
    private var maxNumberOfShownResults: Int {
        let value = UserDefaults(suiteName: "group.balenet.widget")?.integer(forKey: "numberOfDepartures") ?? 0
        return value > 0 ? value : 2
    }

    struct TimetableEntry: TimelineEntry {
        let date: Date
        let stopName: String
        let departures: [Departure]

        static let example = TimetableEntry(
            date: Date(),
            stopName: "Merisotilaantori",
            departures: [
                Departure(departureTime: Date(), routeShortName: "4", headsign: "Munkkiniemi", mode: "TRAM"),
                Departure(departureTime: Date(), routeShortName: "550", headsign: "Munkkiniemi", mode: "BUS")
            ]
        )

        static let example1Departure = TimetableEntry(
            date: Date(),
            stopName: "Merisotilaantori",
            departures: [
                Departure(departureTime: Date().addingTimeInterval(5 * 60), routeShortName: "4", headsign: "Munkkiniemi", mode: "TRAM")
            ]
        )

        static let example2Departures = TimetableEntry(
            date: Date(),
            stopName: "Merisotilaantori",
            departures: [
                Departure(departureTime: Date().addingTimeInterval(5 * 60), routeShortName: "4", headsign: "Munkkiniemi", mode: "TRAM"),
                Departure(departureTime: Date().addingTimeInterval(12 * 60), routeShortName: "550H", headsign: "Kamppi", mode: "BUS")
            ]
        )

        static let example3Departures = TimetableEntry(
            date: Date(),
            stopName: "Merisotilaantori",
            departures: [
                Departure(departureTime: Date().addingTimeInterval(5 * 60), routeShortName: "4", headsign: "Munkkiniemi", mode: "TRAM"),
                Departure(departureTime: Date().addingTimeInterval(12 * 60), routeShortName: "5", headsign: "Kamppi", mode: "TRAM"),
                Departure(departureTime: Date().addingTimeInterval(18 * 60), routeShortName: "7", headsign: "Töölö", mode: "TRAM")
            ]
        )

        static let example4Departures = TimetableEntry(
            date: Date(),
            stopName: "Merisotilaantori",
            departures: [
                Departure(departureTime: Date().addingTimeInterval(3 * 60), routeShortName: "4", headsign: "Munkkiniemi", mode: "TRAM"),
                Departure(departureTime: Date().addingTimeInterval(8 * 60), routeShortName: "550", headsign: "Westendinasema", mode: "BUS"),
                Departure(departureTime: Date().addingTimeInterval(15 * 60), routeShortName: "7", headsign: "Töölö", mode: "TRAM"),
                Departure(departureTime: Date().addingTimeInterval(22 * 60), routeShortName: "4", headsign: "Katajanokka", mode: "TRAM")
            ]
        )
    }

    // MARK: - TimelineProvider

    func placeholder(in context: Context) -> TimetableEntry {
        TimetableEntry.example
    }

    func getSnapshot(in context: Context, completion: @escaping (TimetableEntry) -> ()) {
        completion(TimetableEntry.example)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TimetableEntry>) -> ()) {

        print("========== Widget Timeline Reload ==========")

        Task {
            let now = Date()

            // 1. Resolve favorite stop (or return "no favorites" timeline)
            guard let favoritesTimelineOrStop = makeFavoritesOrStop(now: now) else {
                // No favorites: we already completed in helper
                return
            }

            switch favoritesTimelineOrStop {
            case .timeline(let timeline):
                completion(timeline)
                return

            case .stop(let closestStop):
                // 2. Fetch departures
                let departures = await fetchFilteredDepartures(for: closestStop)

                // 3. Determine how many departures to show based on widget family
                let maxShown = context.family == .systemSmall ? 3 : maxNumberOfShownResults

                // 4. Build entries from departures
                let entries = buildTimelineEntries(
                    for: closestStop,
                    departures: departures,
                    now: now,
                    maxShown: maxShown
                )

                // 5. Always return at least one entry to avoid stale widget content
                let safeEntries = entries.isEmpty
                    ? [TimetableEntry(date: now,
                                      stopName: closestStop.name,
                                      departures: [])]
                    : entries

                // 6. Refresh after 15 minutes
                let refreshDate = now.addingTimeInterval(15 * 60)
                let timeline = Timeline(entries: safeEntries, policy: .after(refreshDate))
                completion(timeline)
            }
        }
    }

    // MARK: - Helpers

    /// Either returns a ready-made "no favorites" timeline, or a resolved closest stop.
    private func makeFavoritesOrStop(now: Date) -> FavoritesResolutionResult? {
        let favorites = favoritesManager.getFavorites()
        print("Widget: Retrieved \(favorites.count) favorites from FavoritesManager")

        guard !favorites.isEmpty else {
            print("Widget: No favorites found, showing empty state")

            let entry = TimetableEntry(
                date: now,
                stopName: "No favorites",
                departures: []
            )

            let timeline = Timeline(
                entries: [entry],
                policy: .after(now.addingTimeInterval(60 * 60))
            )

            return .timeline(timeline)
        }

        let currentLocation = locationManager.getSharedLocation()
        if let loc = currentLocation {
            print("Widget: Current location: \(loc.coordinate.latitude), \(loc.coordinate.longitude)")
        } else {
            print("Widget: No location available, will use alphabetical fallback")
        }

        let closestStop = findClosestStop(
            favorites: favorites,
            currentLocation: currentLocation
        )

        print("Widget: Selected stop: \(closestStop.name) (ID: \(closestStop.id))")
        if closestStop.hasFilters {
            print("Widget: Stop has filters configured")
            if let lines = closestStop.filteredLines {
                print("Widget: Filtered lines: \(lines.joined(separator: ", "))")
            }
            if let pattern = closestStop.filteredHeadsignPattern {
                print("Widget: Filtered headsign pattern: \(pattern)")
            }
        }
        print("==========================================")

        return .stop(closestStop)
    }

    /// Fetch departures and apply stop-specific filters.
    private func fetchFilteredDepartures(for stop: Stop) async -> [Departure] {
        let allDepartures = await HslApi.shared.fetchDepartures(
            stationId: stop.id,
            numberOfResults: Self.numberOfFetchedResults
        )

        let departures = allDepartures.filter { stop.matchesFilters(departure: $0) }
        print("Widget: Filtered departures: \(departures.count) of \(allDepartures.count)")
        return departures.sorted { $0.departureTime < $1.departureTime }
    }

    /// Build the list of timeline entries from a sorted departures list.
    /// - Ensures:
    ///   - Only future departures are shown
    ///   - At most `maxShown` per entry
    ///   - Multiple entries as a sliding window over the list
    private func buildTimelineEntries(
        for stop: Stop,
        departures: [Departure],
        now: Date,
        maxShown: Int
    ) -> [TimetableEntry] {

        // Keep only departures in the future
        let futureDepartures = departures.filter { $0.departureTime > now }

        guard !futureDepartures.isEmpty else {
            print("Widget: No future departures for \(stop.name)")
            return []
        }

        // If fewer than we can show, just one entry with all
        if futureDepartures.count <= maxShown {
            print("Widget: Only \(futureDepartures.count) future departures, single entry")
            let entry = TimetableEntry(
                date: now,
                stopName: stop.name,
                departures: futureDepartures
            )
            return [entry]
        }

        // Sliding window: [0,1], [1,2], [2,3], ...
        var entries: [TimetableEntry] = []
        var entryDate = now
        let lastStartIndex = futureDepartures.count - maxShown

        for startIndex in 0...lastStartIndex {
            let slice = Array(futureDepartures[startIndex..<(startIndex + maxShown)])

            // Filter relative to the time this entry becomes active
            let validDepartures = slice.filter { $0.departureTime > entryDate }

            guard !validDepartures.isEmpty else { continue }

            let entry = TimetableEntry(
                date: entryDate,
                stopName: stop.name,
                departures: validDepartures
            )
            entries.append(entry)

            // Next entry starts at the time of the first departure in this entry
            if let first = validDepartures.first {
                entryDate = first.departureTime
            }
        }

        print("Widget: Created \(entries.count) timeline entries")
        return entries
    }

    /// Find the closest stop to the current location.
    /// If location is unavailable, return the first favorite alphabetically.
    private func findClosestStop(favorites: [Stop], currentLocation: CLLocation?) -> Stop {
        guard let currentLocation = currentLocation else {
            // Fallback: return first favorite alphabetically by name
            return favorites.sorted(by: { $0.name < $1.name }).first!
        }

        var closestStop = favorites[0]
        var minDistance = Double.greatestFiniteMagnitude

        for stop in favorites {
            if let lat = stop.latitude, let lon = stop.longitude {
                let stopLocation = CLLocation(latitude: lat, longitude: lon)
                let distance = currentLocation.distance(from: stopLocation)

                if distance < minDistance {
                    minDistance = distance
                    closestStop = stop
                }
            }
        }

        return closestStop
    }

    // MARK: - Helper Types

    /// Internal helper to return either a ready timeline or a stop.
    private enum FavoritesResolutionResult {
        case timeline(Timeline<TimetableEntry>)
        case stop(Stop)
    }
}


struct stopInfoEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    /// Time formatter with leading zeros
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    /// Dynamic font sizes based on number of departures
    private var titleFont: Font {
        switch entry.departures.count {
        case 1:
            return .headline
        case 2:
            return .headline
        case 3:
            return .caption
        default:
            return .headline
        }
    }

    private var routeFont: Font {
        switch entry.departures.count {
        case 1:
            return .headline
        case 2:
            return .headline
        case 3:
            return .caption
        default:
            return .headline
        }
    }

    private var timeFont: Font {
        switch entry.departures.count {
        case 1:
            return .headline
        case 2:
            return .headline
        case 3:
            return .caption
        default:
            return .headline
        }
    }

    private var spacing: CGFloat {
        switch entry.departures.count {
        case 1, 2:
            return 3
        case 3:
            return 0
        default:
            return 4
        }
    }

    var body: some View {
        switch family {
        case .accessoryInline:
            inlineView
        case .systemSmall:
            systemSmallView
        default:
            // Rectangular widgets show compact layout
            rectangularView
        }
    }

    /// Rectangular widget layout (lock screen)
    private var rectangularView: some View {
        VStack(alignment: .leading, spacing: spacing) {
            if entry.departures.isEmpty {
                emptyStateView
            } else {
                Text(entry.stopName)
                    .font(titleFont)
                    .widgetAccentable()
                    .lineLimit(1)

                ForEach(entry.departures) { departure in
                    HStack(spacing: 4) {
                        Label(departure.routeShortName, systemImage: transitModeIconName(for: departure.mode))
                            .font(routeFont)
                            .lineLimit(1)
                        Spacer()
                        Label {
                            Text(Self.timeFormatter.string(from: departure.departureTime))
                                .font(timeFont)
                                .monospacedDigit()
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        } icon: {
                            Image(systemName: "clock")
                        }
                    }
                }
            }
        }
    }

    /// Home screen small widget layout with more space
    private var systemSmallView: some View {
        VStack(alignment: .leading, spacing: 3) {
            if entry.departures.isEmpty {
                emptyStateView
            } else {
                // Stop name
                Text(entry.stopName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .widgetAccentable()
                    .lineLimit(1)

                Divider()

                // Show up to 3 departures with destination
                ForEach(entry.departures.prefix(3)) { departure in
                    VStack(alignment: .leading, spacing: 1) {
                        HStack(spacing: 4) {
                            // Route with icon
                            Label {
                                Text(departure.routeShortName)
                            } icon: {
                                Image(systemName: transitModeIconName(for: departure.mode))
                                    .foregroundColor(transitModeColor(for: departure.mode))
                            }
                            .font(.caption)
                            .fontWeight(.medium)

                            Spacer()

                            // Time
                            Text(Self.timeFormatter.string(from: departure.departureTime))
                                .font(.caption)
                                .monospacedDigit()
                        }

                        // Destination
                        Text(departure.headsign)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
        }
    }

    /// Empty state when no favorites are configured
    private var emptyStateView: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("No favorites")
                .font(.headline)
                .widgetAccentable()
            Text("Open the app to select favorite stops")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    /// Compact view for inline widget showing only the next departure
    @ViewBuilder
    private var inlineView: some View {
        if let nextDeparture = entry.departures.first {
            Label {
                Text("\(nextDeparture.routeShortName)  \(Self.timeFormatter.string(from: nextDeparture.departureTime))")
            } icon: {
                Image(systemName: transitModeIconName(for: nextDeparture.mode, filled: false))
            }
        } else {
            Label {
                Text("No departures")
            } icon: {
                Image(systemName: "tram")
            }
        }
    }
}

struct stopInfo: Widget {
    let kind: String = "stopInfo"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                stopInfoEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                stopInfoEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("My Widget")
        .description("This is an example widget.")
        .supportedFamilies([.accessoryRectangular, .accessoryInline, .systemSmall])
    }
}

#Preview("1 Departure", as: .accessoryRectangular) {
    stopInfo()
} timeline: {
    Provider.TimetableEntry.example1Departure
}

#Preview("2 Departures", as: .accessoryRectangular) {
    stopInfo()
} timeline: {
    Provider.TimetableEntry.example2Departures
}

#Preview("3 Departures", as: .accessoryRectangular) {
    stopInfo()
} timeline: {
    Provider.TimetableEntry.example3Departures
}

#Preview("Inline", as: .accessoryInline) {
    stopInfo()
} timeline: {
    Provider.TimetableEntry.example1Departure
}

#Preview("System Small", as: .systemSmall) {
    stopInfo()
} timeline: {
    Provider.TimetableEntry.example4Departures
}
