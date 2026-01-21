//
//  DebugDeparturesView.swift
//  HslWidget
//
//  Debug view showing detailed departure information
//

import SwiftUI
import CoreLocation

struct DebugDeparturesView: View {
    @State private var departures: [Departure] = []
    @State private var isLoading = false
    @State private var fetchTime: Date?
    @State private var stopName: String = ""
    @State private var stopId: String = ""
    @State private var errorMessage: String?
    @State private var locationStatus: String = ""

    private let favoritesManager = FavoritesManager.shared
    private let sharedDefaults = UserDefaults(suiteName: "group.balenet.widget")
    private let locationManager = LocationManager.shared
    private let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f
    }()
    private let dateTimeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return f
    }()

    var body: some View {
        List {
            widgetInfoSection
            fetchInfoSection
            if let error = errorMessage {
                errorSection(error)
            }
            if !departures.isEmpty {
                departuresSection
            }
        }
        .navigationTitle("Debug Departures")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: fetchDepartures) {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(isLoading)
            }
        }
        .onAppear {
            fetchDepartures()
        }
    }

    // MARK: - Sections

    private var widgetInfoSection: some View {
        Section {
            if let widgetFetchTime = sharedDefaults?.object(forKey: "widgetLastFetchTime") as? Date {
                LabeledContent("Widget last fetch") {
                    Text(dateTimeFormatter.string(from: widgetFetchTime))
                        .font(.caption)
                        .monospaced()
                }
                let timeSince = Date().timeIntervalSince(widgetFetchTime)
                LabeledContent("Time since fetch") {
                    Text(formatTimeInterval(timeSince))
                        .font(.caption)
                        .monospaced()
                        .foregroundColor(timeSince > 900 ? .orange : .primary) // Orange if > 15 min
                }
            } else {
                Text("Widget has not fetched data yet")
                    .foregroundColor(.secondary)
            }
            if let widgetStop = sharedDefaults?.string(forKey: "widgetLastFetchStop") {
                LabeledContent("Widget stop") {
                    Text(widgetStop)
                        .font(.caption)
                }
            }
        } header: {
            Text("Widget Timeline")
        } footer: {
            Text("Shows when the widget extension last fetched departure data from the API.")
        }
    }

    private var fetchInfoSection: some View {
        Section {
            if isLoading {
                HStack {
                    ProgressView()
                    Text("Fetching...")
                        .foregroundColor(.secondary)
                }
            } else {
                LabeledContent("Stop") {
                    Text(stopName.isEmpty ? "No favorites" : stopName)
                }
                LabeledContent("Stop ID") {
                    Text(stopId.isEmpty ? "-" : stopId)
                        .font(.caption)
                        .monospaced()
                }
                if !locationStatus.isEmpty {
                    LabeledContent("Location") {
                        Text(locationStatus)
                            .font(.caption)
                            .monospaced()
                    }
                }
                if let time = fetchTime {
                    LabeledContent("Fetched at") {
                        Text(timeFormatter.string(from: time))
                            .monospaced()
                    }
                    LabeledContent("Current time") {
                        Text(timeFormatter.string(from: Date()))
                            .monospaced()
                    }
                }
            }
        } header: {
            Text("Fetch Info")
        }
    }

    private func errorSection(_ error: String) -> some View {
        Section {
            Text(error)
                .foregroundColor(.red)
        } header: {
            Text("Error")
        }
    }

    private var departuresSection: some View {
        Section {
            ForEach(Array(departures.enumerated()), id: \.element.id) { index, departure in
                DepartureDebugRow(index: index + 1, departure: departure, timeFormatter: timeFormatter)
            }
        } header: {
            Text("Departures (\(departures.count))")
        }
    }

    // MARK: - Actions

    private func fetchDepartures() {
        isLoading = true
        errorMessage = nil

        Task {
            let favorites = favoritesManager.getFavorites()

            guard !favorites.isEmpty else {
                await MainActor.run {
                    isLoading = false
                    stopName = ""
                    stopId = ""
                    locationStatus = ""
                    errorMessage = "No favorites configured. Add a favorite stop first."
                }
                return
            }

            // Use location to find closest stop, just like the widget does
            let currentLocation = locationManager.currentLocation ?? locationManager.getSharedLocation()
            let closestStop = findClosestStop(favorites: favorites, currentLocation: currentLocation)

            let locStatus: String
            if let loc = currentLocation {
                locStatus = String(format: "%.4f, %.4f", loc.coordinate.latitude, loc.coordinate.longitude)
            } else {
                locStatus = "No location (using alphabetical fallback)"
            }

            let fetchedDepartures = await HslApi.shared.fetchDepartures(
                stationId: closestStop.id,
                numberOfResults: 10
            )

            await MainActor.run {
                self.departures = fetchedDepartures
                self.fetchTime = Date()
                self.stopName = closestStop.name
                self.stopId = closestStop.id
                self.locationStatus = locStatus
                self.isLoading = false

                if fetchedDepartures.isEmpty {
                    self.errorMessage = "No departures returned from API"
                }
            }
        }
    }

    /// Find the closest stop to the current location (same logic as widget)
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

    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        if minutes > 0 {
            return "\(minutes)m \(seconds)s ago"
        } else {
            return "\(seconds)s ago"
        }
    }
}

// MARK: - Departure Row

private struct DepartureDebugRow: View {
    let index: Int
    let departure: Departure
    let timeFormatter: DateFormatter

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header: route and headsign
            HStack {
                Text("#\(index)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 24)
                Text(departure.routeShortName)
                    .font(.headline)
                    .foregroundColor(modeColor)
                Text("→ \(departure.headsign)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            // Times grid
            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 4) {
                GridRow {
                    Text("Scheduled:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(timeFormatter.string(from: departure.departureTime))
                        .font(.caption)
                        .monospaced()
                }
                GridRow {
                    Text("Realtime:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(timeFormatter.string(from: departure.realtimeDepartureTime))
                        .font(.caption)
                        .monospaced()
                        .foregroundColor(departure.delaySeconds != 0 ? .orange : .primary)
                }
                GridRow {
                    Text("Delay:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatDelay(departure.delaySeconds))
                        .font(.caption)
                        .monospaced()
                        .foregroundColor(delayColor)
                }
            }

            // Realtime status
            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(departure.hasRealtimeData ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                    Text(departure.hasRealtimeData ? "Realtime" : "Scheduled only")
                        .font(.caption2)
                }

                if let state = departure.realtimeState {
                    Text("State: \(state)")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(stateColor(state).opacity(0.2))
                        .cornerRadius(4)
                }

                if let platform = departure.platformCode {
                    Text("P\(platform)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            // Service day (raw debug info)
            if let serviceDay = departure.serviceDay {
                Text("Service day: \(formatServiceDay(serviceDay)) (ts: \(Int(serviceDay)))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .monospaced()
            }
        }
        .padding(.vertical, 4)
    }

    private var modeColor: Color {
        switch departure.mode {
        case "TRAM": return .green
        case "BUS": return .blue
        case "RAIL": return .purple
        case "SUBWAY": return .orange
        case "FERRY": return .cyan
        default: return .primary
        }
    }

    private var delayColor: Color {
        if departure.delaySeconds > 60 {
            return .red
        } else if departure.delaySeconds < -60 {
            return .blue
        } else {
            return .primary
        }
    }

    private func formatDelay(_ seconds: Int) -> String {
        if seconds == 0 {
            return "0s (on time)"
        } else if seconds > 0 {
            return "+\(seconds)s (+\(seconds / 60)m late)"
        } else {
            return "\(seconds)s (\(abs(seconds) / 60)m early)"
        }
    }

    private func stateColor(_ state: String) -> Color {
        switch state {
        case "SCHEDULED": return .gray
        case "UPDATED": return .green
        case "CANCELED": return .red
        case "ADDED": return .blue
        case "MODIFIED": return .orange
        default: return .gray
        }
    }

    private func formatServiceDay(_ timestamp: Double) -> String {
        let date = Date(timeIntervalSince1970: timestamp)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

#Preview {
    NavigationView {
        DebugDeparturesView()
    }
}
