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

        static let example = TimetableEntry(date: Date(), stopName: "Merisotilaantori", departures: [Departure(departureTime: Date(), routeShortName: "4", headsign: "Munkkiniemi"), Departure(departureTime: Date(), routeShortName: "5", headsign: "Munkkiniemi")])
    }

    func placeholder(in context: Context) -> TimetableEntry {
        TimetableEntry.example
    }

    func getSnapshot(in context: Context, completion: @escaping (TimetableEntry) -> ()) {
        let entry = TimetableEntry.example
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TimetableEntry>) -> ()) {

        print("========== Widget Timeline Reload ==========")

        Task {
            // Get favorite stops
            let favorites = favoritesManager.getFavorites()
            print("Widget: Retrieved \(favorites.count) favorites from FavoritesManager")

            // Handle no favorites case
            guard !favorites.isEmpty else {
                print("Widget: No favorites found, showing empty state")
                let entry = TimetableEntry(date: Date(), stopName: "No favorites", departures: [])
                let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(60 * 60)))
                completion(timeline)
                return
            }

            // Get current location
            let currentLocation = locationManager.getSharedLocation()
            if let loc = currentLocation {
                print("Widget: Current location: \(loc.coordinate.latitude), \(loc.coordinate.longitude)")
            } else {
                print("Widget: No location available, will use alphabetical fallback")
            }

            // Find closest favorite stop
            let closestStop = findClosestStop(favorites: favorites, currentLocation: currentLocation)

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

            // Fetch departures for the closest stop
            let allDepartures = await HslApi.shared.fetchDepartures(stationId: closestStop.id, numberOfResults: Provider.numberOfFetchedResults)

            // Apply filters if configured
            let filteredDepartures = allDepartures.filter { closestStop.matchesFilters(departure: $0) }
            print("Widget: Filtered departures: \(filteredDepartures.count) of \(allDepartures.count)")

            // Filter out past departures to prevent showing stale data
            let now = Date()
            let departures = filteredDepartures.filter { $0.departureTime > now }
            print("Widget: Future departures: \(departures.count) of \(filteredDepartures.count)")

            var entries: [TimetableEntry] = []
            let lastValidIndex = max(0, departures.count - Provider.maxNumberOfShownResults)

            // Iterate over the fetched departures to create timeline entries
            for index in 0..<lastValidIndex {
                let entryDate = (index == 0 ? Date() : departures[index-1].departureTime)
                let nextDepartures = Array(departures[index..<(index + Provider.maxNumberOfShownResults)])
                let entry = TimetableEntry(date: entryDate, stopName: closestStop.name, departures: nextDepartures)
                entries.append(entry)
            }

            // Determine when to refresh the timeline
            // Refresh after the last shown departure, or in 15 minutes if no departures
            let refreshDate: Date
            if let lastDeparture = departures.last {
                // Add a small buffer (30 seconds) after the last departure to ensure fresh data
                refreshDate = lastDeparture.departureTime.addingTimeInterval(30)
            } else {
                // No departures available, try again in 15 minutes
                refreshDate = Date().addingTimeInterval(15 * 60)
            }

            let timeline = Timeline(entries: entries, policy: .after(refreshDate))
            completion(timeline)
        }
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

