//
//  HeadsignPreloader.swift
//  HslWidget
//
//  Handles preloading of headsigns for nearby stops
//

import Foundation
import CoreLocation

class HeadsignPreloader: ObservableObject {
    @Published var isLoading = false
    @Published var loadingProgress = 0
    @Published var totalStops = 0
    @Published var loadingMessage = ""

    private let cache = HeadsignCache.shared
    private let api = HslApi.shared

    /// Filter stops within a given radius from a location
    func stopsWithinRadius(stops: [Stop], from location: CLLocation, radius: Double) -> [Stop] {
        return stops.filter { stop in
            guard let lat = stop.latitude, let lon = stop.longitude else {
                return false
            }
            let stopLocation = CLLocation(latitude: lat, longitude: lon)
            return location.distance(from: stopLocation) <= radius
        }
    }

    /// Preload headsigns for stops within radius
    func preloadNearbyHeadsigns(allStops: [Stop], userLocation: CLLocation?, radius: Double = 5000) async -> [String: [String]] {
        // Determine location to use
        let location: CLLocation
        if let userLocation = userLocation {
            location = userLocation
        } else {
            // Fallback to Helsinki city center if no location available
            print("HeadsignPreloader: No user location, using Helsinki city center as fallback")
            location = CLLocation(latitude: 60.1699, longitude: 24.9384)
        }

        // Filter stops by distance
        let nearbyStops = stopsWithinRadius(stops: allStops, from: location, radius: radius)

        await MainActor.run {
            totalStops = nearbyStops.count
            loadingProgress = 0
            loadingMessage = "Loading \(nearbyStops.count) nearby stops..."
        }

        print("HeadsignPreloader: Preloading headsigns for \(nearbyStops.count) stops within \(Int(radius))m")

        var stopHeadsigns: [String: [String]] = [:]

        // Process in batches to avoid overwhelming the API
        let batchSize = 50
        let batches = nearbyStops.chunked(into: batchSize)

        for (batchIndex, batch) in batches.enumerated() {
            // Use TaskGroup for parallel processing within each batch
            await withTaskGroup(of: (String, [String]).self) { group in
                for stop in batch {
                    group.addTask {
                        // Fetch headsigns from all stop IDs that share this code
                        let stopIdsToFetch = stop.allStopIds ?? [stop.id]
                        var allHeadsigns: [String] = []

                        // Fetch headsigns for each direction
                        for stopId in stopIdsToFetch {
                            let headsigns = await self.api.fetchHeadsigns(stopId: stopId)
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

                        return (stop.id, Array(uniqueHeadsigns.prefix(4)))
                    }
                }

                // Collect results
                for await (stopId, headsigns) in group {
                    if !headsigns.isEmpty {
                        stopHeadsigns[stopId] = headsigns
                    }
                }
            }

            // Update progress
            let processedCount = min((batchIndex + 1) * batchSize, nearbyStops.count)
            await MainActor.run {
                loadingProgress = processedCount
                loadingMessage = "Loaded \(processedCount)/\(nearbyStops.count) stops..."
            }

            // Small delay between batches to be respectful to the API
            if batchIndex < batches.count - 1 {
                try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
            }
        }

        print("HeadsignPreloader: Preload complete, cached \(stopHeadsigns.count) stops with headsigns")
        return stopHeadsigns
    }

    /// Load or refresh headsigns cache
    func loadOrRefreshCache(allStops: [Stop], userLocation: CLLocation?, radius: Double = 5000, forceRefresh: Bool = false) async -> [String: [String]] {
        // Check if we should use cached data
        if !forceRefresh, let cachedHeadsigns = cache.loadCache(), !cache.shouldRefreshCache(currentLocation: userLocation, radius: radius) {
            print("HeadsignPreloader: Using cached headsigns (\(cachedHeadsigns.count) stops)")
            return cachedHeadsigns
        }

        // Preload headsigns
        await MainActor.run {
            isLoading = true
        }

        let stopHeadsigns = await preloadNearbyHeadsigns(allStops: allStops, userLocation: userLocation, radius: radius)

        // Save to cache
        cache.saveCache(stopHeadsigns, location: userLocation, radius: radius)

        await MainActor.run {
            isLoading = false
        }

        return stopHeadsigns
    }
}

// Extension to chunk arrays into batches
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
