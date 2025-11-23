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

    static let numberOfFetchedResults = 20
    static let refreshInterval: TimeInterval = 15 * 60 // 15 minutes

    private let favoritesManager = FavoritesManager.shared
    private let locationReader = SharedLocationReader()

    // MARK: - Public API

    /// Build a complete timeline for the widget
    func buildTimeline(
        now: Date,
        maxShown: Int,
        completion: @escaping (Timeline<TimetableEntry>) -> Void
    ) {
        // Use Task.detached to avoid capturing self and prevent retain cycles
        Task.detached { [weak favoritesManager, locationReader] in
            MemoryLogger.log("Timeline Start")

            guard let favoritesManager = favoritesManager else {
                return
            }

            // 1. Get favorites
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
                    policy: .after(now.addingTimeInterval(Self.refreshInterval))
                )
                await MainActor.run {
                    completion(timeline)
                }
                MemoryLogger.log("Timeline End (No Favorites)")
                return
            }

            // 2. Find closest stop
            let currentLocation = locationReader.getSharedLocation()
            let closestStop = TimelineBuilder.findClosestStop(
                favorites: favorites,
                currentLocation: currentLocation
            )

            debugLog("Widget: Selected stop: \(closestStop.name) (ID: \(closestStop.id))")

            MemoryLogger.log("Before API Call")

            // 3. Fetch departures
            let allDepartures = await HslApi.shared.fetchDepartures(
                stationId: closestStop.id,
                numberOfResults: Self.numberOfFetchedResults
            )
            let departures = allDepartures
                .filter { closestStop.matchesFilters(departure: $0) }
                .sorted { $0.departureTime < $1.departureTime }

            MemoryLogger.log("After API Call")

            // 4. Build entries
            let entries = self.buildTimelineEntries(
                for: closestStop,
                departures: departures,
                now: now,
                maxShown: maxShown
            )

            MemoryLogger.log("After Building Entries")

            // 5. Create timeline
            let safeEntries = entries.isEmpty
                ? [TimetableEntry(date: now,
                                  stopName: closestStop.name,
                                  departures: [],
                                  state: .noDepartures)]
                : entries

            let refreshDate = now.addingTimeInterval(Self.refreshInterval)
            let timeline = Timeline(entries: safeEntries, policy: .after(refreshDate))

            MemoryLogger.log("Before Completion")
            await MainActor.run {
                completion(timeline)
            }
            MemoryLogger.log("Timeline End")
        }
    }

    /// Moved to static to avoid capturing self
    private static func findClosestStop(favorites: [Stop], currentLocation: CLLocation?) -> Stop {
        guard let currentLocation = currentLocation else {
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

    // MARK: - Private Helpers

    /// Build the list of timeline entries from a sorted departures list
    /// Creates entries at departure times to update exactly when vehicles leave
    /// Limited to first 6 departures to minimize memory usage
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

        // Create entries at departure times (widget updates when vehicles leave)
        // Limit to 6 entries for memory efficiency
        var entries: [TimetableEntry] = []
        let maxEntries = 6
        var entryDate = now

        for startIndex in 0..<min(futureDepartures.count - maxShown + 1, maxEntries) {
            // Get the slice of departures to show in this entry
            let endIndex = min(startIndex + maxShown, futureDepartures.count)
            let slice = Array(futureDepartures[startIndex..<endIndex])

            // Filter to only future departures relative to when this entry becomes active
            let validDepartures = slice.filter { $0.departureTime > entryDate }

            guard !validDepartures.isEmpty else { break }

            let entry = TimetableEntry(
                date: entryDate,
                stopName: stop.name,
                departures: validDepartures,
                state: .normal
            )
            entries.append(entry)

            // Next entry starts when the first departure in current entry leaves
            if let firstDeparture = validDepartures.first {
                entryDate = firstDeparture.departureTime
            }
        }

        debugLog("Widget: Created \(entries.count) timeline entries")
        return entries
    }

}
