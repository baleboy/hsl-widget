//
//  TimelineBuilder.swift
//  stopInfo
//
//  Created by Claude Code
//

import Foundation
import CoreLocation
import WidgetKit

/// Builds widget timeline entries from favorites and departures data
struct TimelineBuilder {

    static let numberOfFetchedResults = 12

    private let favoritesManager = FavoritesManager.shared
    private let locationReader = SharedLocationReader()

    /// Either returns a ready-made "no favorites" timeline, or a resolved closest stop
    enum FavoritesResolutionResult {
        case timeline(Timeline<TimetableEntry>)
        case stop(Stop)
    }

    // MARK: - Public API

    /// Build a complete timeline for the widget
    func buildTimeline(
        now: Date,
        maxShown: Int,
        completion: @escaping (Timeline<TimetableEntry>) -> Void
    ) {
        Task { [completion] in
            // 1. Resolve favorite stop (or return "no favorites" timeline)
            guard let favoritesTimelineOrStop = makeFavoritesOrStop(now: now) else {
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
                    now: now,
                    maxShown: maxShown
                )

                // 4. Always return at least one entry to avoid stale widget content
                let safeEntries = entries.isEmpty
                    ? [TimetableEntry(date: now,
                                      stopName: closestStop.name,
                                      departures: [],
                                      state: .noDepartures)]
                    : entries

                // 5. Refresh after 15 minutes
                let refreshDate = now.addingTimeInterval(15 * 60)
                let timeline = Timeline(entries: safeEntries, policy: .after(refreshDate))
                completion(timeline)
            }
        }
    }

    // MARK: - Private Helpers

    /// Either returns a ready-made "no favorites" timeline, or a resolved closest stop
    private func makeFavoritesOrStop(now: Date) -> FavoritesResolutionResult? {
        let favorites = favoritesManager.getFavorites()
        debugLog("Widget: Retrieved \(favorites.count) favorites from FavoritesManager")

        guard !favorites.isEmpty else {
            debugLog("Widget: No favorites found, showing empty state")

            let entry = TimetableEntry(
                date: now,
                stopName: "",
                departures: [],
                state: .noFavorites
            )

            let timeline = Timeline(
                entries: [entry],
                policy: .after(now.addingTimeInterval(60 * 60))
            )

            return .timeline(timeline)
        }

        let currentLocation = locationReader.getSharedLocation()
        if let loc = currentLocation {
            debugLog("Widget: Current location: \(loc.coordinate.latitude), \(loc.coordinate.longitude)")
        } else {
            debugLog("Widget: No location available, will use alphabetical fallback")
        }

        let closestStop = findClosestStop(
            favorites: favorites,
            currentLocation: currentLocation
        )

        debugLog("Widget: Selected stop: \(closestStop.name) (ID: \(closestStop.id))")
        if closestStop.hasFilters {
            debugLog("Widget: Stop has filters configured")
            if let lines = closestStop.filteredLines {
                debugLog("Widget: Filtered lines: \(lines.joined(separator: ", "))")
            }
            if let pattern = closestStop.filteredHeadsignPattern {
                debugLog("Widget: Filtered headsign pattern: \(pattern)")
            }
        }
        debugLog("==========================================")

        return .stop(closestStop)
    }

    /// Fetch departures and apply stop-specific filters
    private func fetchFilteredDepartures(for stop: Stop) async -> [Departure] {
        let allDepartures = await HslApi.shared.fetchDepartures(
            stationId: stop.id,
            numberOfResults: Self.numberOfFetchedResults
        )

        let departures = allDepartures.filter { stop.matchesFilters(departure: $0) }
        debugLog("Widget: Filtered departures: \(departures.count) of \(allDepartures.count)")
        return departures.sorted { $0.departureTime < $1.departureTime }
    }

    /// Build the list of timeline entries from a sorted departures list
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
            debugLog("Widget: No future departures for \(stop.name)")
            return []
        }

        // If fewer than we can show, just one entry with all
        if futureDepartures.count <= maxShown {
            debugLog("Widget: Only \(futureDepartures.count) future departures, single entry")
            let entry = TimetableEntry(
                date: now,
                stopName: stop.name,
                departures: futureDepartures,
                state: .normal
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
                departures: validDepartures,
                state: .normal
            )
            entries.append(entry)

            // Next entry starts at the time of the first departure in this entry
            if let first = validDepartures.first {
                entryDate = first.departureTime
            }
        }

        debugLog("Widget: Created \(entries.count) timeline entries")
        return entries
    }

    /// Find the closest stop to the current location
    /// If location is unavailable, return the first favorite alphabetically
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
}
