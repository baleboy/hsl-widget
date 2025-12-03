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
    @State private var stopHeadsigns: [String: [String]] = [:] // stopId -> headsigns
    @State private var headsignFetchTask: Task<Void, Never>? = nil
    @StateObject private var locationManager = LocationManager.shared
    @StateObject private var preloader = HeadsignPreloader()
    @State private var isInitialLoad = true
    @State private var isFetchingInitialHeadsigns = false

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
                VStack(spacing: 16) {
                    ProgressView()
                    Text("Loading stops...")
                        .font(.roundedHeadline)
                }
            } else if preloader.isLoading && isInitialLoad {
                // Show loading screen with progress during initial headsign preload
                VStack(spacing: 20) {
                    ProgressView(value: Double(preloader.loadingProgress), total: Double(preloader.totalStops))
                        .progressViewStyle(.linear)
                        .frame(width: 200)

                    VStack(spacing: 8) {
                        Text("Loading nearby stops")
                            .font(.roundedHeadline)
                        Text(preloader.loadingMessage)
                            .font(.roundedSubheadline)
                            .foregroundColor(.secondary)
                    }

                    Text("This only happens once in a while")
                        .font(.roundedCaption)
                        .foregroundColor(.secondary)
                }
                .padding()
            } else if isFetchingInitialHeadsigns {
                // Show loading screen while fetching headsigns for visible stops
                VStack(spacing: 16) {
                    ProgressView()
                    Text("Loading stop details...")
                        .font(.roundedHeadline)
                        .foregroundColor(.secondary)
                }
            } else {
                TabView {
                    StopListView(
                        stops: sortedStops,
                        stopHeadsigns: stopHeadsigns,
                        favoriteStopIds: favoriteStopIds,
                        onToggleFavorite: toggleFavorite
                    )
                    .tabItem {
                        Label("List", systemImage: "list.bullet")
                    }

                    StopMapView(
                        stops: sortedStops,
                        searchTerm: $searchTerm,
                        favoriteStopIds: $favoriteStopIds,
                        onToggleFavorite: toggleFavorite
                    )
                    .tabItem {
                        Label("Map", systemImage: "map")
                    }
                }
                .searchable(text: $searchTerm, prompt: "Search by name or code")
                .navigationBarTitle("Select Stops", displayMode: .inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            onDismiss()
                        }
                    }
                }
                .onAppear {
                    loadFavorites()
                }
                .onChange(of: sortedStops) { oldStops, newStops in
                    // Cancel any pending fetch task
                    headsignFetchTask?.cancel()

                    // Lazy load headsigns for distant stops that aren't in cache
                    headsignFetchTask = Task {
                        try? await Task.sleep(nanoseconds: 300_000_000) // 300ms delay
                        guard !Task.isCancelled else { return }
                        await fetchHeadsignsForVisibleStops(newStops)
                    }
                }
            }
        }
        .task {
            // Set fetching state immediately at the start to prevent showing incomplete UI
            await MainActor.run {
                isFetchingInitialHeadsigns = true
            }

            // Load all stops first
            stops = await HslApi.shared.fetchAllStops()

            // Load or refresh headsign cache for nearby stops
            let userLocation = locationManager.currentLocation ?? locationManager.getSharedLocation()
            let cachedHeadsigns = await preloader.loadOrRefreshCache(
                allStops: stops,
                userLocation: userLocation,
                radius: 5000
            )

            // Populate stopHeadsigns with cached data
            stopHeadsigns = cachedHeadsigns

            // Fetch headsigns for initially visible stops before showing the list
            await fetchHeadsignsForVisibleStops(sortedStops)

            // Now show the list with all data ready
            await MainActor.run {
                isFetchingInitialHeadsigns = false
                isInitialLoad = false
            }
        }
    }

    private func toggleFavorite(_ stop: Stop) {
        print("StopPicker: Toggling favorite for: \(stop.name)")

        // Update UI optimistically FIRST for instant feedback
        let isCurrentlyFavorite = favoriteStopIds.contains(stop.id)
        if isCurrentlyFavorite {
            favoriteStopIds.remove(stop.id)
        } else {
            favoriteStopIds.insert(stop.id)
        }
        print("StopPicker: Current favorites count: \(favoriteStopIds.count)")

        // Then do the I/O operations asynchronously
        Task {
            let stopWithHeadsigns = Stop(
                id: stop.id,
                name: stop.name,
                code: stop.code,
                latitude: stop.latitude,
                longitude: stop.longitude,
                vehicleModes: stop.vehicleModes,
                headsigns: stopHeadsigns[stop.id] ?? stop.headsigns,
                allStopIds: stop.allStopIds,
                filteredLines: stop.filteredLines,
                filteredHeadsignPattern: stop.filteredHeadsignPattern
            )

            favoritesManager.toggleFavorite(stopWithHeadsigns)
        }

        // Dismiss the search keyboard so the "Done" button becomes clear
        hideKeyboard()
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
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

    private func fetchHeadsignsForVisibleStops(_ stops: [Stop]) async {
        // Fetch headsigns for top 20 stops to avoid too many API calls
        let stopsToFetch = Array(stops.prefix(20))

        // Collect all headsigns before updating UI
        var newHeadsigns: [String: [String]] = [:]

        for stop in stopsToFetch {
            // Skip if we already have headsigns for this stop
            if stopHeadsigns[stop.id] != nil {
                continue
            }

            // Fetch headsigns from ALL stop IDs that share this code (to get all directions)
            let stopIdsToFetch = stop.allStopIds ?? [stop.id]
            var allHeadsigns: [String] = []

            for stopId in stopIdsToFetch {
                let headsigns = await HslApi.shared.fetchHeadsigns(stopId: stopId)
                allHeadsigns.append(contentsOf: headsigns)
            }

            // Remove duplicates while preserving order
            var uniqueHeadsigns: [String] = []
            var seen = Set<String>()
            for headsign in allHeadsigns {
                if !seen.contains(headsign) {
                    uniqueHeadsigns.append(headsign)
                    seen.insert(headsign)
                }
            }

            if !uniqueHeadsigns.isEmpty {
                newHeadsigns[stop.id] = Array(uniqueHeadsigns.prefix(4)) // Show up to 4 headsigns
            }
        }

        // Update UI once with all collected headsigns
        await MainActor.run {
            for (stopId, headsigns) in newHeadsigns {
                stopHeadsigns[stopId] = headsigns
            }
        }
    }
}

#Preview {
    StopPickerView(onDismiss: {})
}
