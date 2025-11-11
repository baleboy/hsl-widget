//
//  stopInfo.swift
//  stopInfo
//
//  Created by Francesco Balestrieri on 5.5.2024.
//

import CoreLocation
import SwiftUI
import WidgetKit

/// A wrapper for CLLocationManager that provides async/await-based location fetching.
///
/// This class handles the complex coordination between CLLocationManager's delegate-based API
/// and Swift's modern async/await concurrency model. It manages authorization requests and
/// location updates, providing a simple async interface for requesting the user's current location.
///
/// ## Thread Safety
/// This class is annotated with `@MainActor` to ensure all interactions with CLLocationManager
/// and state management occur on the main thread, as required by CoreLocation.
///
/// ## Single Request Limitation
/// Only one location request can be active at a time. If a new request is made while a previous
/// request is still pending, the previous request will be cancelled and return `nil`.
///
/// ## Authorization Handling
/// - If location services are disabled system-wide, returns `nil` immediately
/// - If authorization is denied or restricted, returns `nil`
/// - If authorization is not determined, requests "when in use" authorization
/// - Automatically handles authorization state changes and resumes pending requests
///
/// ## Usage
/// ```swift
/// let fetcher = LocationFetcher()
/// if let location = await fetcher.requestLocation() {
///     // Use location
/// } else {
///     // Location unavailable (disabled, denied, or error)
/// }
/// ```
@MainActor
final class LocationFetcher: NSObject, CLLocationManagerDelegate {

    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<CLLocation?, Never>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    /// Requests the user's current location asynchronously.
    ///
    /// This method checks location services availability and authorization status before
    /// requesting location. If necessary, it will request authorization from the user.
    ///
    /// - Returns: The user's current location, or `nil` if:
    ///   - Location services are disabled
    ///   - Authorization is denied or restricted
    ///   - A location error occurs
    ///   - A new request cancels this one
    ///
    /// - Note: Only one request can be active at a time. If this method is called while
    ///   a previous request is pending, the previous request will be cancelled and return `nil`.
    func requestLocation() async -> CLLocation? {
        guard CLLocationManager.locationServicesEnabled() else {
            return nil
        }

        switch manager.authorizationStatus {
        case .denied, .restricted:
            return nil
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        default:
            break
        }

        return await withCheckedContinuation { continuation in
            if let existingContinuation = self.continuation {
                existingContinuation.resume(returning: nil)
            }
            self.continuation = continuation

            if self.manager.authorizationStatus == .authorizedAlways ||
                self.manager.authorizationStatus == .authorizedWhenInUse {
                self.manager.requestLocation()
            }
        }
    }

    /// CLLocationManagerDelegate method called when location updates are available.
    ///
    /// Resumes the pending continuation with the first available location and clears
    /// the continuation to prepare for the next request.
    ///
    /// - Parameters:
    ///   - manager: The location manager that generated the update
    ///   - locations: An array of location objects in chronological order
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        continuation?.resume(returning: locations.first)
        continuation = nil
    }

    /// CLLocationManagerDelegate method called when a location request fails.
    ///
    /// Resumes the pending continuation with `nil` and clears the continuation.
    ///
    /// - Parameters:
    ///   - manager: The location manager that encountered the error
    ///   - error: The error that occurred
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        continuation?.resume(returning: nil)
        continuation = nil
    }

    /// CLLocationManagerDelegate method called when authorization status changes.
    ///
    /// If authorization is granted while a request is pending, this automatically triggers
    /// the location request. If authorization is denied or restricted, any pending request
    /// is cancelled and returns `nil`.
    ///
    /// - Parameter manager: The location manager whose authorization status changed
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            manager.requestLocation()
        case .denied, .restricted:
            continuation?.resume(returning: nil)
            continuation = nil
        default:
            break
        }
    }
}

struct Provider: TimelineProvider {

    static let fallbackStop = Stop.defaultStop
    static let maxNumberOfShownResults = 2
    static let numberOfFetchedResults = 20

    struct TimetableEntry: TimelineEntry {
        let date: Date
        let stopName: String
        let departures: [Departure]

        static let example = TimetableEntry(
            date: Date(),
            stopName: Stop.defaultStop.name,
            departures: [
                Departure(departureTime: Date(), routeShortName: "4", headsign: "Munkkiniemi"),
                Departure(departureTime: Date(), routeShortName: "5", headsign: "Munkkiniemi")
            ]
        )
    }

    func placeholder(in context: Context) -> TimetableEntry {
        TimetableEntry.example
    }

    func getSnapshot(in context: Context, completion: @escaping (TimetableEntry) -> ()) {
        let entry = TimetableEntry.example
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TimetableEntry>) -> ()) {

        print("Reloading timeline")

        let defaults = UserDefaults(suiteName: "group.balenet.widget")
        let favoriteStops = FavoriteStopsStore.load(from: defaults)

        Task {
            let selectedStop = await stopForTimeline(from: favoriteStops, defaults: defaults)
            let departures = await HslApi.shared.fetchDepartures(
                stationId: selectedStop.id,
                numberOfResults: Provider.numberOfFetchedResults
            )

            var entries: [TimetableEntry] = []
            let lastValidIndex = max(0,departures.count - Provider.maxNumberOfShownResults)

            // Iterate over the fetched departures to create timeline entries
            for index in 0..<lastValidIndex {
                let entryDate = (index == 0 ? Date() : departures[index-1].departureTime)
                let nextDepartures = Array(departures[index..<(index + Provider.maxNumberOfShownResults)])
                let entry = TimetableEntry(date: entryDate, stopName: selectedStop.name, departures: nextDepartures)
                entries.append(entry)
            }

            let timeline = Timeline(entries: entries, policy: .atEnd)
            completion(timeline)
        }
    }

    private func stopForTimeline(from favorites: [Stop], defaults: UserDefaults?) async -> Stop {
        if let closestFavorite = await closestFavorite(from: favorites) {
            return closestFavorite
        }

        if let legacyStop = FavoriteStopsStore.loadLegacyStop(from: defaults) {
            return legacyStop
        }

        return Provider.fallbackStop
    }

    private func closestFavorite(from favorites: [Stop]) async -> Stop? {
        guard !favorites.isEmpty else { return nil }

        if favorites.count == 1 {
            return favorites.first
        }

        guard let location = await LocationFetcher().requestLocation() else {
            return favorites.first
        }

        return favorites.min { lhs, rhs in
            lhs.distance(from: location) < rhs.distance(from: location)
        }
    }
}


struct stopInfoEntryView : View {
    var entry: Provider.Entry
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(entry.stopName)
                .font(.headline)
                .widgetAccentable()
            ForEach(entry.departures) { departure in
                HStack {
                    Label(departure.routeShortName, systemImage: "tram.fill")
                        .font(.headline)
                    Label {
                        Text(departure.departureTime, style: .time)
                    } icon: {
                        Image(systemName: "clock")
                    }.padding(.leading)
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
