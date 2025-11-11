//
//  stopInfo.swift
//  stopInfo
//
//  Created by Francesco Balestrieri on 5.5.2024.
//

import CoreLocation
import SwiftUI
import WidgetKit

@MainActor
final class LocationFetcher: NSObject, CLLocationManagerDelegate {

    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<CLLocation?, Never>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func requestLocation() async -> CLLocation? {
        guard CLLocationManager.locationServicesEnabled() else {
            return nil
        }

        switch manager.authorizationStatus {
        case .denied, .restricted:
            return nil
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
            return nil
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

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        continuation?.resume(returning: locations.first)
        continuation = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        continuation?.resume(returning: nil)
        continuation = nil
    }

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
