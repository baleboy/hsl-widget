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
    @State private var filteredHeadsigns: [String: [String]] = [:] // stopId -> headsigns for filtered lines
    @State private var filteredLinesByMode: [String: [String: [String]]] = [:] // stopId -> [mode: [lines]]
    @State private var showingSettings = false
    @StateObject private var locationManager = LocationManager.shared

    private let favoritesManager = FavoritesManager.shared

    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 0) {
                    if favorites.isEmpty {
                        EmptyFavoritesView(onAddStop: { showingStopPicker = true })
                    } else {
                        List {
                            // Next departures section
                            if let closestStop = closestStop {
                                NextDeparturesView(
                                    stop: closestStop,
                                    departures: departures,
                                    isLoading: isLoadingDepartures
                                )
                            }

                            // All favorites section
                            Section(header: Text("Favorite stops")) {
                                ForEach(favorites) { stop in
                                    FavoriteStopRow(
                                        stop: stop,
                                        isClosest: stop.id == closestStop?.id,
                                        filteredHeadsigns: filteredHeadsigns[stop.id],
                                        linesByMode: filteredLinesByMode[stop.id],
                                        onTap: { editFilters(for: stop) }
                                    )
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
                }

                // Fixed floating button at the bottom
                if !favorites.isEmpty {
                    VStack {
                        Spacer()
                        Button(action: {
                            showingStopPicker = true
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color(.systemBackground))
                                    .frame(width: 64, height: 64)
                                    .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)

                                Image(systemName: "plus.circle.fill")
                                    .font(.rounded(size: 64))
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationTitle("HSL Widget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gear")
                    }
                }
            }
            .onAppear {
                loadFavorites()
                requestLocationPermission()
                updateClosestStopAndDepartures()
            }
            .onChange(of: locationManager.currentLocation) {
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
            .sheet(isPresented: $showingSettings) {
                SettingsView()
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

        // Refresh data for this stop (fetches lines for all stops now)
        Task {
            await fetchFilteredHeadsigns()
        }
    }

    private func loadFavorites() {
        favorites = favoritesManager.getFavorites()
        print("FavoritesListView: Loaded \(favorites.count) favorites")

        // Clean up stale entries for stops no longer in favorites
        let favoriteIds = Set(favorites.map { $0.id })
        filteredHeadsigns = filteredHeadsigns.filter { favoriteIds.contains($0.key) }
        filteredLinesByMode = filteredLinesByMode.filter { favoriteIds.contains($0.key) }

        // Fetch headsigns for filtered stops
        Task {
            await fetchFilteredHeadsigns()
        }
    }

    /// Fetch headsigns and lines for all favorite stops
    private func fetchFilteredHeadsigns() async {
        // Fetch for all favorite stops
        for stop in favorites {
            // Fetch departures for this stop
            let allDepartures = await HslApi.shared.fetchDepartures(stationId: stop.id, numberOfResults: 30)

            let filteredLines = stop.filteredLines

            // Extract headsigns and lines
            var headsignsForLines: [String] = []
            var seenHeadsigns = Set<String>()

            // Group ALL lines by mode (for display)
            var allLinesByMode: [String: Set<String>] = [:] // mode -> set of lines

            // Group filtered lines by mode (for headsigns)
            var filteredLinesByModeSet: [String: Set<String>] = [:] // mode -> set of lines

            for departure in allDepartures {
                // Collect all lines by mode for display
                if let mode = departure.mode {
                    var lines = allLinesByMode[mode] ?? Set<String>()
                    lines.insert(departure.routeShortName)
                    allLinesByMode[mode] = lines
                }

                // If this stop has filters, collect headsigns and filtered lines
                if let filteredLines = filteredLines, !filteredLines.isEmpty {
                    if filteredLines.contains(departure.routeShortName) {
                        // Collect headsigns for filtered lines
                        if !seenHeadsigns.contains(departure.headsign) {
                            headsignsForLines.append(departure.headsign)
                            seenHeadsigns.insert(departure.headsign)
                        }

                        // Group filtered lines by mode
                        if let mode = departure.mode {
                            var lines = filteredLinesByModeSet[mode] ?? Set<String>()
                            lines.insert(departure.routeShortName)
                            filteredLinesByModeSet[mode] = lines
                        }
                    }
                }
            }

            // Decide which lines to display
            var linesToDisplay: [String: [String]]
            if let filteredLines = filteredLines, !filteredLines.isEmpty {
                // Show only filtered lines
                var linesByModeArrays: [String: [String]] = [:]
                for (mode, linesSet) in filteredLinesByModeSet {
                    linesByModeArrays[mode] = Array(linesSet)
                }
                linesToDisplay = linesByModeArrays
            } else {
                // Show all lines
                var linesByModeArrays: [String: [String]] = [:]
                for (mode, linesSet) in allLinesByMode {
                    linesByModeArrays[mode] = Array(linesSet)
                }
                linesToDisplay = linesByModeArrays
            }

            // Store the headsigns and lines by mode
            await MainActor.run {
                if let filteredLines = filteredLines, !filteredLines.isEmpty {
                    filteredHeadsigns[stop.id] = headsignsForLines
                } else {
                    filteredHeadsigns[stop.id] = nil
                }
                filteredLinesByMode[stop.id] = linesToDisplay
            }
        }
    }

    private func removeFavorite(_ stop: Stop) {
        favoritesManager.removeFavorite(stop)

        // Clear filtered data for this stop
        filteredHeadsigns[stop.id] = nil
        filteredLinesByMode[stop.id] = nil

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
