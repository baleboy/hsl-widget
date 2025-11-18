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

    static let maxNumberOfShownResults = 2
    static let numberOfFetchedResults = 20

    private let favoritesManager = FavoritesManager.shared
    private let locationManager = LocationManager.shared

    struct TimetableEntry: TimelineEntry {
        let date: Date
        let stopName: String
        let departures: [Departure]

        static let example = TimetableEntry(
            date: Date(),
            stopName: "Merisotilaantori",
            departures: [
                Departure(departureTime: Date(), routeShortName: "4", headsign: "Munkkiniemi"),
                Departure(departureTime: Date(), routeShortName: "5", headsign: "Munkkiniemi")
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

                // 3. Build entries from departures
                let entries = buildTimelineEntries(
                    for: closestStop,
                    departures: departures,
                    now: now
                )

                // 4. Always return at least one entry to avoid stale widget content
                let safeEntries = entries.isEmpty
                    ? [TimetableEntry(date: now,
                                      stopName: closestStop.name,
                                      departures: [])]
                    : entries

                // 5. Refresh after 15 minutes
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
    ///   - At most `maxNumberOfShownResults` per entry
    ///   - Multiple entries as a sliding window over the list
    private func buildTimelineEntries(
        for stop: Stop,
        departures: [Departure],
        now: Date
    ) -> [TimetableEntry] {

        // Keep only departures in the future
        let futureDepartures = departures.filter { $0.departureTime > now }

        guard !futureDepartures.isEmpty else {
            print("Widget: No future departures for \(stop.name)")
            return []
        }

        let maxShown = Self.maxNumberOfShownResults

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

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if entry.departures.isEmpty {
                // Show message when no favorites are selected
                VStack(alignment: .leading, spacing: 2) {
                    Text("No favorites")
                        .font(.headline)
                        .widgetAccentable()
                    Text("Open the app to select favorite stops")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            } else {
                // Show stop name and departures
                Text(entry.stopName)
                    .font(.headline)
                    .widgetAccentable()

                ForEach(entry.departures) { departure in
                    HStack(spacing: 4) {
                        Label(departure.routeShortName, systemImage: "tram.fill")
                            .font(.headline)
                        Spacer()
                        Label {
                            Text(departure.departureTime, style: .time)
                                .monospacedDigit()
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        } icon: {
                            Image(systemName: "clock")
                        }
                    }
                }
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
        .supportedFamilies([.accessoryRectangular, .systemSmall])
    }
}

#Preview(as: .accessoryRectangular) {
    stopInfo()
} timeline: {
    Provider.TimetableEntry.example
}

#Preview(as: .systemSmall) {
    stopInfo()
} timeline: {
    Provider.TimetableEntry.example
}

