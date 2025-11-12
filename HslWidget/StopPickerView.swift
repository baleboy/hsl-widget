//
//  StopPickerView.swift
//  HslWidget
//
//  Stop picker with distance-based sorting
//

import SwiftUI
import CoreLocation

struct StopPickerView: View {
    @State private var stops = [Stop]()
    @State private var searchTerm = ""
    @State private var favoriteStopIds = Set<String>()
    @StateObject private var locationManager = LocationManager.shared

    private let favoritesManager = FavoritesManager.shared
    let onDismiss: () -> Void

    var sortedStops: [Stop] {
        let stopsToSort = filteredStops

        // If we have location, sort by distance
        if let currentLocation = locationManager.currentLocation ?? locationManager.getSharedLocation() {
            return stopsToSort.sorted { stop1, stop2 in
                let distance1 = distanceToStop(stop1, from: currentLocation)
                let distance2 = distanceToStop(stop2, from: currentLocation)
                return distance1 < distance2
            }
        }

        // No location, sort alphabetically
        return stopsToSort.sorted { $0.name < $1.name }
    }

    var filteredStops: [Stop] {
        guard !searchTerm.isEmpty else {
            return stops
        }
        return stops.filter {
            $0.name.localizedCaseInsensitiveContains(searchTerm) ||
            $0.code.localizedCaseInsensitiveContains(searchTerm)
        }
    }

    var body: some View {
        NavigationView {
            if stops.isEmpty {
                Text("Loading...").font(.title)
            } else {
                List {
                    ForEach(sortedStops) { stop in
                        stopRow(stop)
                    }
                }
                .searchable(text: $searchTerm, prompt: "Search by name or code")
                .navigationBarTitle("Select Stops", displayMode: .inline)
                .navigationBarItems(trailing: Button("Done") {
                    onDismiss()
                })
                .onAppear {
                    loadFavorites()
                }
            }
        }
        .task {
            stops = await HslApi.shared.fetchAllStops()
        }
    }

    private func stopRow(_ stop: Stop) -> some View {
        Button(action: {
            toggleFavorite(stop)
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(stop.name)
                        .foregroundColor(.primary)
                    HStack {
                        Text(stop.code)
                            .font(.caption)
                            .foregroundColor(.secondary)

                        // Show distance if available
                        if let distance = formattedDistance(to: stop) {
                            Text("•")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(distance)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                Spacer()
                if favoriteStopIds.contains(stop.id) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func toggleFavorite(_ stop: Stop) {
        print("StopPicker: Toggling favorite for: \(stop.name)")
        favoritesManager.toggleFavorite(stop)
        loadFavorites()
        print("StopPicker: Current favorites count: \(favoriteStopIds.count)")
    }

    private func loadFavorites() {
        let favorites = favoritesManager.getFavorites()
        favoriteStopIds = Set(favorites.map { $0.id })
        print("StopPicker: Loaded \(favoriteStopIds.count) favorites")
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
    StopPickerView(onDismiss: {})
}
