//
//  FavoritesListView.swift
//  HslWidget
//
//  Main view showing favorite stops with button to add more
//

import SwiftUI
import CoreLocation

struct FavoritesListView: View {
    private static let sharedDefaults = UserDefaults(suiteName: "group.balenet.widget")

    @State private var favorites: [Stop] = []
    @State private var showingStopPicker = false
    @State private var stopToEdit: Stop?
    @State private var closestStop: Stop?
    @State private var departures: [Departure] = []
    @State private var isLoadingDepartures = false
    @State private var filteredHeadsigns: [String: [String]] = [:] // stopId -> headsigns for filtered lines
    @State private var filteredLinesByMode: [String: [String: [String]]] = [:] // stopId -> [mode: [lines]]
    @State private var showingSettings = false
    @State private var isInitialLoad = true
    @State private var isRefreshing = false
    @State private var showFilterTooltip = false
    @State private var showingPaywall = false
    @StateObject private var locationManager = LocationManager.shared

    @AppStorage("hasShownFilterTooltip", store: sharedDefaults)
    private var hasShownFilterTooltip = false

    private let favoritesManager = FavoritesManager.shared

    var sortedFavorites: [Stop] {
        guard let currentLocation = locationManager.currentLocation ?? locationManager.getSharedLocation() else {
            // No location available, return favorites in original order
            return favorites
        }

        return favorites.sorted { stop1, stop2 in
            let distance1 = distanceToStop(stop1, from: currentLocation)
            let distance2 = distanceToStop(stop2, from: currentLocation)
            return distance1 < distance2
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 0) {
                    if (isInitialLoad || isRefreshing) && !favorites.isEmpty {
                        // Show loading indicator during data fetch
                        VStack(spacing: 16) {
                            ProgressView()
                            Text("Loading departures...")
                                .font(.roundedHeadline)
                                .foregroundColor(.secondary)
                        }
                    } else if favorites.isEmpty {
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
                                ForEach(sortedFavorites) { stop in
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
                        .refreshable {
                            await refreshData()
                        }
                    }
                }

                // Fixed floating button at the bottom
                if !favorites.isEmpty {
                    VStack {
                        Spacer()
                        Button(action: {
                            if favoritesManager.hasReachedFreeLimit() {
                                showingPaywall = true
                            } else {
                                showingStopPicker = true
                            }
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
                        Image(systemName: "gearshape.fill")
                    }
                }
            }
            .onAppear {
                requestLocationPermission()
                loadAllData()
            }
            .onChange(of: locationManager.currentLocation) {
                // When location changes, update the closest stop
                // but fetch all data together to avoid incremental UI updates
                Task {
                    guard !favorites.isEmpty else { return }

                    let currentLocation = locationManager.currentLocation ?? locationManager.getSharedLocation()
                    let newClosest = findClosestStop(favorites: favorites, currentLocation: currentLocation)

                    // Only update if the closest stop changed
                    guard newClosest.id != closestStop?.id else { return }

                    // Fetch departures for the new closest stop
                    let allDepartures = await HslApi.shared.fetchDepartures(stationId: newClosest.id, numberOfResults: 10)
                    let filteredDepartures = allDepartures.filter { newClosest.matchesFilters(departure: $0) }

                    // Update UI with all data at once
                    await MainActor.run {
                        self.closestStop = newClosest
                        self.departures = filteredDepartures
                        self.isLoadingDepartures = false
                    }
                }
            }
            .sheet(isPresented: $showingStopPicker) {
                StopPickerView(onDismiss: {
                    showingStopPicker = false
                    // Reload data after adding/removing favorites (coordinated update)
                    Task {
                        let newFavorites = favoritesManager.getFavorites()

                        // Fetch headsigns for all stops IN PARALLEL
                        await fetchHeadsignsForStops(newFavorites)

                        // Find closest and fetch its departures
                        let currentLocation = locationManager.currentLocation ?? locationManager.getSharedLocation()
                        let newClosest = findClosestStop(favorites: newFavorites, currentLocation: currentLocation)
                        let allDepartures = await HslApi.shared.fetchDepartures(stationId: newClosest.id, numberOfResults: 10)
                        let filteredDepartures = allDepartures.filter { newClosest.matchesFilters(departure: $0) }

                        // Update all UI state at once
                        await MainActor.run {
                            favorites = newFavorites
                            closestStop = newClosest
                            departures = filteredDepartures
                        }
                    }
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
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
            .onChange(of: showingSettings) { oldValue, newValue in
                // Reload data when settings sheet is dismissed
                if oldValue && !newValue {
                    loadAllData()
                }
            }
            .overlay {
                if showFilterTooltip {
                    FilterTooltipView(onDismiss: dismissFilterTooltip)
                }
            }
        }
    }

    private func showFilterTooltipIfNeeded() {
        // Show tooltip only once, after onboarding, when there are favorites
        if !hasShownFilterTooltip && !favorites.isEmpty {
            // Small delay to let the UI settle
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation {
                    showFilterTooltip = true
                }
            }
        }
    }

    private func dismissFilterTooltip() {
        withAnimation {
            showFilterTooltip = false
            hasShownFilterTooltip = true
        }
    }

    /// Load all data (favorites, headsigns, and departures) before showing the UI
    private func loadAllData() {
        Task {
            // If we're not on initial load, set refreshing state
            if !isInitialLoad {
                await MainActor.run {
                    isRefreshing = true
                }
            }

            // Load favorites synchronously first
            favorites = favoritesManager.getFavorites()
            print("FavoritesListView: Loaded \(favorites.count) favorites")

            guard !favorites.isEmpty else {
                await MainActor.run {
                    isInitialLoad = false
                    isRefreshing = false
                }
                return
            }

            // Fetch headsigns for all stops
            await fetchFilteredHeadsigns()

            // Find closest stop and fetch its departures
            let currentLocation = locationManager.currentLocation ?? locationManager.getSharedLocation()
            let closest = findClosestStop(favorites: favorites, currentLocation: currentLocation)

            // Fetch departures for closest stop
            let allDepartures = await HslApi.shared.fetchDepartures(stationId: closest.id, numberOfResults: 10)
            let filteredDepartures = allDepartures.filter { closest.matchesFilters(departure: $0) }

            await MainActor.run {
                self.closestStop = closest
                self.departures = filteredDepartures
                self.isLoadingDepartures = false
                self.isInitialLoad = false
                self.isRefreshing = false  // Clear refresh state after ALL data is ready
                print("FavoritesListView: All data loaded, showing UI")
                showFilterTooltipIfNeeded()
            }
        }
    }

    /// Refresh data when user pulls to refresh
    private func refreshData() async {
        // Request fresh location
        locationManager.requestImmediateLocation()

        // Small delay to allow location update to process
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

        // Reload favorites from storage
        let newFavorites = favoritesManager.getFavorites()

        guard !newFavorites.isEmpty else {
            await MainActor.run {
                favorites = []
                filteredHeadsigns = [:]
                filteredLinesByMode = [:]
                closestStop = nil
                departures = []
            }
            return
        }

        // Fetch headsigns for all stops in parallel
        await fetchHeadsignsForStops(newFavorites)

        // Find closest stop with potentially updated location
        let currentLocation = locationManager.currentLocation ?? locationManager.getSharedLocation()
        let closest = findClosestStop(favorites: newFavorites, currentLocation: currentLocation)

        // Fetch departures for closest stop
        let allDepartures = await HslApi.shared.fetchDepartures(stationId: closest.id, numberOfResults: 10)
        let filteredDepartures = allDepartures.filter { closest.matchesFilters(departure: $0) }

        await MainActor.run {
            self.favorites = newFavorites
            self.closestStop = closest
            self.departures = filteredDepartures
        }
    }

    private func editFilters(for stop: Stop) {
        stopToEdit = stop
    }

    private func saveFilteredStop(_ stop: Stop) {
        favoritesManager.updateFavorite(stop)

        // Refresh all data after saving filters (coordinated update)
        Task {
            let newFavorites = favoritesManager.getFavorites()

            // Fetch headsigns for all stops IN PARALLEL
            await fetchHeadsignsForStops(newFavorites)

            // Find closest and fetch its departures
            let currentLocation = locationManager.currentLocation ?? locationManager.getSharedLocation()
            let newClosest = findClosestStop(favorites: newFavorites, currentLocation: currentLocation)
            let allDepartures = await HslApi.shared.fetchDepartures(stationId: newClosest.id, numberOfResults: 10)
            let filteredDepartures = allDepartures.filter { newClosest.matchesFilters(departure: $0) }

            // Update all UI state at once
            await MainActor.run {
                favorites = newFavorites
                closestStop = newClosest
                departures = filteredDepartures
            }
        }
    }

    /// Process departures for a stop and return headsigns and lines
    private func processStopDepartures(stop: Stop, allDepartures: [Departure]) async -> (headsigns: [String]?, linesByMode: [String: [String]]) {
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

        // Return headsigns and lines
        let headsigns: [String]? = (filteredLines != nil && !filteredLines!.isEmpty) ? headsignsForLines : nil
        return (headsigns: headsigns, linesByMode: linesToDisplay)
    }

    /// Fetch headsigns and lines for all favorite stops (in parallel)
    private func fetchFilteredHeadsigns() async {
        await fetchHeadsignsForStops(favorites)
    }

    /// Fetch headsigns and lines for given stops in parallel
    private func fetchHeadsignsForStops(_ stops: [Stop]) async {
        // Collect all data first before updating UI
        var newFilteredHeadsigns: [String: [String]] = [:]
        var newFilteredLinesByMode: [String: [String: [String]]] = [:]

        // Fetch for all stops IN PARALLEL using TaskGroup
        await withTaskGroup(of: (String, [String]?, [String: [String]]).self) { group in
            for stop in stops {
                group.addTask {
                    let allDepartures = await HslApi.shared.fetchDepartures(stationId: stop.id, numberOfResults: 15)
                    let result = await self.processStopDepartures(stop: stop, allDepartures: allDepartures)
                    return (stop.id, result.headsigns, result.linesByMode)
                }
            }

            // Collect results as they complete
            for await (stopId, headsigns, linesByMode) in group {
                if let headsigns = headsigns {
                    newFilteredHeadsigns[stopId] = headsigns
                }
                newFilteredLinesByMode[stopId] = linesByMode
            }
        }

        // Update UI once with all collected data
        await MainActor.run {
            filteredHeadsigns = newFilteredHeadsigns
            filteredLinesByMode = newFilteredLinesByMode
        }
    }

    private func removeFavorite(_ stop: Stop) {
        // Optimistically update UI immediately to prevent flicker
        favorites.removeAll { $0.id == stop.id }

        // Persist the change
        favoritesManager.removeFavorite(stop)

        // Reload data after removing favorite (coordinated update)
        Task {
            let newFavorites = favoritesManager.getFavorites()

            guard !newFavorites.isEmpty else {
                // If no favorites left, just clear everything
                await MainActor.run {
                    favorites = []
                    filteredHeadsigns = [:]
                    filteredLinesByMode = [:]
                    closestStop = nil
                    departures = []
                }
                return
            }

            // Fetch headsigns for all remaining stops IN PARALLEL
            await fetchHeadsignsForStops(newFavorites)

            // Find closest and fetch its departures
            let currentLocation = locationManager.currentLocation ?? locationManager.getSharedLocation()
            let newClosest = findClosestStop(favorites: newFavorites, currentLocation: currentLocation)
            let allDepartures = await HslApi.shared.fetchDepartures(stationId: newClosest.id, numberOfResults: 10)
            let filteredDepartures = allDepartures.filter { newClosest.matchesFilters(departure: $0) }

            // Update all UI state at once
            await MainActor.run {
                favorites = newFavorites
                closestStop = newClosest
                departures = filteredDepartures
            }
        }
    }

    private func requestLocationPermission() {
        print("FavoritesListView: Requesting location permission")
        locationManager.requestPermission()
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

    private func distanceToStop(_ stop: Stop, from location: CLLocation) -> Double {
        guard let lat = stop.latitude, let lon = stop.longitude else {
            return Double.greatestFiniteMagnitude
        }
        let stopLocation = CLLocation(latitude: lat, longitude: lon)
        return location.distance(from: stopLocation)
    }
}

#Preview {
    FavoritesListView()
}
