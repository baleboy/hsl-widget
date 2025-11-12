//
//  FavoritesListView.swift
//  HslWidget
//
//  Main view showing favorite stops with button to add more
//

import SwiftUI
import CoreLocation

struct FavoritesListView: View {
    @State private var favorites: [Stop] = []
    @State private var showingStopPicker = false
    @State private var stopToEdit: Stop?
    @State private var closestStop: Stop?
    @State private var departures: [Departure] = []
    @State private var isLoadingDepartures = false
    @StateObject private var locationManager = LocationManager.shared

    private let favoritesManager = FavoritesManager.shared

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if favorites.isEmpty {
                    // Empty state
                    VStack(spacing: 16) {
                        Image(systemName: "star.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("No favorite stops selected")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Text("Tap the button below to select your favorite stops")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    // Departures section and favorites list
                    List {
                        // Next departures section
                        if let closestStop = closestStop {
                            Section(header: Text("Next Departures")) {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: "location.fill")
                                            .foregroundColor(.blue)
                                            .font(.caption)
                                        Text(closestStop.name)
                                            .font(.headline)
                                    }

                                    if isLoadingDepartures {
                                        HStack {
                                            ProgressView()
                                                .scaleEffect(0.8)
                                            Text("Loading...")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        .padding(.vertical, 4)
                                    } else if departures.isEmpty {
                                        Text("No departures available")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .padding(.vertical, 4)
                                    } else {
                                        ForEach(departures.prefix(3)) { departure in
                                            HStack {
                                                Label(departure.routeShortName, systemImage: "tram.fill")
                                                    .font(.headline)
                                                Spacer()
                                                Text(departure.departureTime, style: .time)
                                                    .font(.headline)
                                            }
                                            .padding(.vertical, 2)
                                        }
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }

                        // All favorites section
                        Section(header: Text("All Favorites")) {
                            ForEach(favorites) { stop in
                                Button(action: {
                                    editFilters(for: stop)
                                }) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Text(stop.name)
                                                .font(.headline)
                                                .foregroundColor(.primary)
                                            Spacer()
                                            if stop.hasFilters {
                                                Image(systemName: "line.3.horizontal.decrease.circle.fill")
                                                    .foregroundColor(.blue)
                                                    .font(.caption)
                                            }
                                            if stop.id == closestStop?.id {
                                                Image(systemName: "location.fill")
                                                    .foregroundColor(.blue)
                                                    .font(.caption)
                                            }
                                            Image(systemName: "star.fill")
                                                .foregroundColor(.yellow)
                                        }
                                        HStack {
                                            Text(stop.code)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            if stop.hasFilters {
                                                Text("• Filtered")
                                                    .font(.caption)
                                                    .foregroundColor(.blue)
                                            }
                                        }

                                        // Show headsigns (directions) if available
                                        if let headsigns = stop.headsigns, !headsigns.isEmpty {
                                            HStack(spacing: 4) {
                                                Image(systemName: "arrow.right")
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                                Text(headsigns.prefix(3).joined(separator: ", "))
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                                    .lineLimit(1)
                                            }
                                            .padding(.top, 2)
                                        }
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        removeFavorite(stop)
                                    } label: {
                                        Label("Remove", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                }

                // Add favorites button
                Button(action: {
                    showingStopPicker = true
                }) {
                    Label(favorites.isEmpty ? "Select Favorites" : "Add More Favorites", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding()
                }
            }
            .navigationTitle("Favorite Stops")
            .onAppear {
                loadFavorites()
                requestLocationPermission()
                updateClosestStopAndDepartures()
            }
            .onChange(of: locationManager.currentLocation) { _ in
                updateClosestStopAndDepartures()
            }
            .sheet(isPresented: $showingStopPicker) {
                StopPickerView(onDismiss: {
                    showingStopPicker = false
                    loadFavorites()
                    updateClosestStopAndDepartures()
                })
            }
            .sheet(item: $stopToEdit) { stop in
                StopFilterView(
                    stop: stop,
                    onSave: { updatedStop in
                        saveFilteredStop(updatedStop)
                        stopToEdit = nil
                    },
                    onDismiss: {
                        stopToEdit = nil
                    }
                )
            }
        }
    }

    private func editFilters(for stop: Stop) {
        stopToEdit = stop
    }

    private func saveFilteredStop(_ stop: Stop) {
        favoritesManager.updateFavorite(stop)
        loadFavorites()
        updateClosestStopAndDepartures()
    }

    private func loadFavorites() {
        favorites = favoritesManager.getFavorites()
        print("FavoritesListView: Loaded \(favorites.count) favorites")
    }

    private func removeFavorite(_ stop: Stop) {
        favoritesManager.removeFavorite(stop)
        loadFavorites()
        updateClosestStopAndDepartures()
    }

    private func requestLocationPermission() {
        print("FavoritesListView: Requesting location permission")
        locationManager.requestPermission()
    }

    private func updateClosestStopAndDepartures() {
        guard !favorites.isEmpty else {
            closestStop = nil
            departures = []
            return
        }

        // Find closest favorite stop
        let currentLocation = locationManager.currentLocation ?? locationManager.getSharedLocation()
        closestStop = findClosestStop(favorites: favorites, currentLocation: currentLocation)

        // Fetch departures for closest stop
        if let stop = closestStop {
            Task {
                await fetchDepartures(for: stop)
            }
        }
    }

    private func fetchDepartures(for stop: Stop) async {
        isLoadingDepartures = true
        print("FavoritesListView: Fetching departures for \(stop.name)")

        let allDepartures = await HslApi.shared.fetchDepartures(stationId: stop.id, numberOfResults: 20)

        // Apply filters if configured
        let filteredDepartures = allDepartures.filter { stop.matchesFilters(departure: $0) }
        print("FavoritesListView: Filtered departures: \(filteredDepartures.count) of \(allDepartures.count)")

        await MainActor.run {
            self.departures = filteredDepartures
            self.isLoadingDepartures = false
            print("FavoritesListView: Loaded \(filteredDepartures.count) departures")
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

#Preview {
    FavoritesListView()
}
