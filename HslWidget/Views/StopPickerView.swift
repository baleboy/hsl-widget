//
//  StopPickerView.swift
//  HslWidget
//
//  Stop picker with distance-based sorting
//

import SwiftUI
import CoreLocation
import MapKit

enum StopPickerViewMode: String, CaseIterable {
    case map = "Map"
    case list = "List"
}

struct StopPickerView: View {
    @State private var stops: [Stop]
    @State private var searchTerm = ""
    @State private var favoriteStopIds = Set<String>()
    @State private var stopHeadsigns: [String: [String]] // stopId -> headsigns
    @State private var headsignFetchTask: Task<Void, Never>? = nil
    @StateObject private var locationManager = LocationManager.shared
    @StateObject private var preloader = HeadsignPreloader()
    @State private var isInitialLoad = true
    @State private var isFetchingInitialHeadsigns = false
    @State private var viewMode: StopPickerViewMode = .map
    @State private var hasCachedData: Bool

    private let favoritesManager = FavoritesManager.shared
    private let stopsCache = StopsCache.shared
    let onDismiss: () -> Void

    init(onDismiss: @escaping () -> Void) {
        self.onDismiss = onDismiss
        // Load from cache synchronously for instant display
        let cachedStops = StopsCache.shared.loadStops() ?? []
        _stops = State(initialValue: cachedStops)
        _hasCachedData = State(initialValue: !cachedStops.isEmpty)
        _stopHeadsigns = State(initialValue: [:])
    }

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
            if stops.isEmpty && !hasCachedData {
                // Only show loading on first-ever launch (no cache)
                VStack(spacing: 16) {
                    ProgressView()
                    Text("Loading stops...")
                        .font(.roundedHeadline)
                }
            } else if stops.isEmpty && preloader.isLoading {
                // Show loading screen with progress during initial headsign preload (first launch only)
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
            } else {
                VStack(spacing: 0) {
                    viewModePicker

                    if viewMode == .list {
                        listView
                    } else {
                        StopMapView(
                            stops: stops,
                            favoriteStopIds: favoriteStopIds,
                            onToggleFavorite: { stop in
                                toggleFavorite(stop)
                            }
                        )
                    }
                }
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
            }
        }
        .task {
            let userLocation = locationManager.currentLocation ?? locationManager.getSharedLocation()

            // If we already have cached stops, load headsigns in background without blocking UI
            if hasCachedData {
                // Load headsigns from cache synchronously first
                let cachedHeadsigns = await preloader.loadOrRefreshCache(
                    allStops: stops,
                    userLocation: userLocation,
                    radius: 5000
                )
                stopHeadsigns = cachedHeadsigns

                // Fetch any missing headsigns for visible stops
                await fetchHeadsignsForVisibleStops(sortedStops)

                await MainActor.run {
                    isInitialLoad = false
                }

                // Refresh stops in background if cache is stale
                if stopsCache.needsRefresh() {
                    let freshStops = await HslApi.shared.fetchAllStops()
                    if !freshStops.isEmpty {
                        stopsCache.saveStops(freshStops)
                        await MainActor.run {
                            stops = freshStops
                        }
                    }
                }
            } else {
                // First launch: no cache, need to show loading indicators
                await MainActor.run {
                    isFetchingInitialHeadsigns = true
                }

                // Load all stops from API
                let fetchedStops = await HslApi.shared.fetchAllStops()
                stopsCache.saveStops(fetchedStops)

                await MainActor.run {
                    stops = fetchedStops
                }

                // Load or refresh headsign cache for nearby stops
                let cachedHeadsigns = await preloader.loadOrRefreshCache(
                    allStops: fetchedStops,
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
    }

    private var viewModePicker: some View {
        Picker("View Mode", selection: $viewMode) {
            ForEach(StopPickerViewMode.allCases, id: \.self) { mode in
                Text(mode.rawValue).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private var listView: some View {
        List {
            ForEach(sortedStops) { stop in
                stopRow(stop)
            }
        }
        .searchable(text: $searchTerm, prompt: "Search by name or code")
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

    private func stopRow(_ stop: Stop) -> some View {
        Button(action: {
            toggleFavorite(stop)
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
