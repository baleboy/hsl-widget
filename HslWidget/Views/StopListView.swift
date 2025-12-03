//
//  StopListView.swift
//  HslWidget
//
//  List view for selecting favorite stops
//

import SwiftUI
import CoreLocation

struct StopListView: View {
    let stops: [Stop]
    let stopHeadsigns: [String: [String]]
    let favoriteStopIds: Set<String>
    let onToggleFavorite: (Stop) -> Void

    @StateObject private var locationManager = LocationManager.shared

    var body: some View {
        List {
            ForEach(stops) { stop in
                stopRow(stop)
            }
        }
    }

    private func stopRow(_ stop: Stop) -> some View {
        Button(action: {
            onToggleFavorite(stop)
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(stop.name)
                        .foregroundColor(.primary)
                    HStack(spacing: 4) {
                        Text(stop.code)
                            .font(.roundedCaption)
                            .foregroundColor(.secondary)

                        // Show distance if available
                        if let distance = formattedDistance(to: stop) {
                            Text("•")
                                .font(.roundedCaption)
                                .foregroundColor(.secondary)
                            Text(distance)
                                .font(.roundedCaption)
                                .foregroundColor(.secondary)
                        }

                        // Show transport mode icons
                        if let modes = stop.vehicleModes, !modes.isEmpty {
                            Text("•")
                                .font(.roundedCaption)
                                .foregroundColor(.secondary)
                            HStack(spacing: 2) {
                                ForEach(Array(modes.sorted()), id: \.self) { mode in
                                    modeIcon(for: mode)
                                }
                            }
                        }
                    }

                    // Show headsigns (directions) if available
                    if let headsigns = stopHeadsigns[stop.id], !headsigns.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.right")
                                .font(.roundedCaption2)
                                .foregroundColor(.secondary)
                            Text(headsigns.joined(separator: ", "))
                                .font(.roundedCaption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
                Spacer()
                Image(systemName: favoriteStopIds.contains(stop.id) ? "star.fill" : "star")
                    .foregroundColor(favoriteStopIds.contains(stop.id) ? .yellow : .gray)
            }
            .animation(.none, value: favoriteStopIds)
            .contentShape(Rectangle())
        }
    }

    private func modeIcon(for mode: String) -> some View {
        Group {
            switch mode.uppercased() {
            case "BUS":
                Image(systemName: "bus.fill")
                    .foregroundColor(.blue)
            case "TRAM":
                Image(systemName: "tram.fill")
                    .foregroundColor(.green)
            case "RAIL":
                Image(systemName: "train.side.front.car")
                    .foregroundColor(.purple)
            case "SUBWAY":
                Image(systemName: "train.side.front.car")
                    .foregroundColor(.orange)
            case "FERRY":
                Image(systemName: "ferry.fill")
                    .foregroundColor(.cyan)
            default:
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(.gray)
            }
        }
        .font(.roundedCaption)
    }

    private func distanceToStop(_ stop: Stop, from location: CLLocation) -> Double {
        guard let lat = stop.latitude, let lon = stop.longitude else {
            return Double.greatestFiniteMagnitude
        }
        let stopLocation = CLLocation(latitude: lat, longitude: lon)
        return location.distance(from: stopLocation)
    }

    private func formattedDistance(to stop: Stop) -> String? {
        guard let currentLocation = locationManager.currentLocation ?? locationManager.getSharedLocation() else {
            return nil
        }

        let distance = distanceToStop(stop, from: currentLocation)

        if distance == Double.greatestFiniteMagnitude {
            return nil
        }

        if distance < 1000 {
            return String(format: "%.0f m", distance)
        } else {
            return String(format: "%.1f km", distance / 1000)
        }
    }
}

#Preview {
    StopListView(
        stops: [
            Stop(id: "1", name: "Kamppi", code: "H1234", latitude: 60.168992, longitude: 24.931984, vehicleModes: ["BUS"]),
            Stop(id: "2", name: "Rautatientori", code: "H1301", latitude: 60.170877, longitude: 24.943353, vehicleModes: ["TRAM"])
        ],
        stopHeadsigns: ["1": ["Munkkiniemi", "Lauttasaari"]],
        favoriteStopIds: ["1"],
        onToggleFavorite: { _ in }
    )
}
