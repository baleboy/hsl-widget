//
//  HeadsignCache.swift
//  HslWidget
//
//  Manages persistent caching of headsigns with multi-location support
//

import Foundation
import CoreLocation

class HeadsignCache {
    static let shared = HeadsignCache()

    private let sharedDefaults = UserDefaults(suiteName: "group.balenet.widget")

    private let multiCacheKey = "headsignsMultiLocationCache"

    private let cacheExpirationDays = 7 // Refresh weekly
    private let cacheLocationThresholdMeters = 2000.0 // Consider locations within 2km as the same
    private let maxCachedLocations = 5 // Keep 5 most recently used locations

    struct LocationCacheEntry: Codable {
        let latitude: Double
        let longitude: Double
        let timestamp: Date
        let radius: Double
        let stopHeadsigns: [String: [String]] // stopId -> headsigns
        let lastAccessTime: Date
    }

    struct MultiLocationCache: Codable {
        var entries: [String: LocationCacheEntry] // location key -> cache entry
    }

    private init() {}

    /// Generate a unique key for a location (rounded to ~200m precision)
    private func locationKey(latitude: Double, longitude: Double) -> String {
        let lat = round(latitude * 1000) / 1000 // ~111m precision
        let lon = round(longitude * 1000) / 1000 // ~111m precision at equator
        return "\(lat),\(lon)"
    }

    /// Load the multi-location cache from storage
    private func loadMultiCache() -> MultiLocationCache {
        guard let data = sharedDefaults?.data(forKey: multiCacheKey),
              let cache = try? JSONDecoder().decode(MultiLocationCache.self, from: data) else {
            return MultiLocationCache(entries: [:])
        }
        return cache
    }

    /// Save the multi-location cache to storage
    private func saveMultiCache(_ cache: MultiLocationCache) {
        guard let data = try? JSONEncoder().encode(cache) else {
            print("HeadsignCache: Failed to encode multi-location cache")
            return
        }
        sharedDefaults?.set(data, forKey: multiCacheKey)
    }

    /// Find a cached entry near the current location
    private func findNearbyCacheEntry(location: CLLocation, radius: Double, cache: MultiLocationCache) -> (key: String, entry: LocationCacheEntry)? {
        let currentCoord = location.coordinate

        for (key, entry) in cache.entries {
            let entryLocation = CLLocation(latitude: entry.latitude, longitude: entry.longitude)
            let distance = location.distance(from: entryLocation)

            // Check if entry is nearby, not expired, and has matching radius
            if distance <= cacheLocationThresholdMeters {
                let daysSinceCache = Date().timeIntervalSince(entry.timestamp) / (24 * 60 * 60)
                let isExpired = daysSinceCache > Double(cacheExpirationDays)
                let radiusMatches = entry.radius == radius

                if !isExpired && radiusMatches {
                    print("HeadsignCache: Found valid nearby cache entry at \(Int(distance))m away (age: \(String(format: "%.1f", daysSinceCache)) days)")
                    return (key, entry)
                } else if isExpired {
                    print("HeadsignCache: Found nearby cache entry but it's expired (\(String(format: "%.1f", daysSinceCache)) days old)")
                } else if !radiusMatches {
                    print("HeadsignCache: Found nearby cache entry but radius changed (\(entry.radius)m -> \(radius)m)")
                }
            }
        }

        return nil
    }

    /// Check if cache should be refreshed based on time and location
    func shouldRefreshCache(currentLocation: CLLocation?, radius: Double = 5000) -> Bool {
        guard let currentLocation = currentLocation else {
            print("HeadsignCache: No location provided, needs refresh")
            return true
        }

        let cache = loadMultiCache()

        if cache.entries.isEmpty {
            print("HeadsignCache: No cache entries found, needs refresh")
            return true
        }

        // Check if we have a valid nearby cache entry
        if findNearbyCacheEntry(location: currentLocation, radius: radius, cache: cache) != nil {
            return false
        }

        print("HeadsignCache: No valid nearby cache entry found, needs refresh")
        return true
    }

    /// Load cached headsigns for the current location
    func loadCache(currentLocation: CLLocation?, radius: Double = 5000) -> [String: [String]]? {
        guard let currentLocation = currentLocation else {
            print("HeadsignCache: No location provided for cache lookup")
            return nil
        }

        var cache = loadMultiCache()

        guard let (key, entry) = findNearbyCacheEntry(location: currentLocation, radius: radius, cache: cache) else {
            print("HeadsignCache: No valid cache found for current location")
            return nil
        }

        // Update last access time
        var updatedEntry = entry
        updatedEntry = LocationCacheEntry(
            latitude: entry.latitude,
            longitude: entry.longitude,
            timestamp: entry.timestamp,
            radius: entry.radius,
            stopHeadsigns: entry.stopHeadsigns,
            lastAccessTime: Date()
        )
        cache.entries[key] = updatedEntry
        saveMultiCache(cache)

        print("HeadsignCache: Loaded cache with \(entry.stopHeadsigns.count) stops from location (\(entry.latitude), \(entry.longitude))")
        return entry.stopHeadsigns
    }

    /// Save headsigns to cache with location and timestamp
    func saveCache(_ stopHeadsigns: [String: [String]], location: CLLocation?, radius: Double) {
        guard let location = location else {
            print("HeadsignCache: Cannot save cache without location")
            return
        }

        var cache = loadMultiCache()

        let coordinate = location.coordinate
        let key = locationKey(latitude: coordinate.latitude, longitude: coordinate.longitude)

        let newEntry = LocationCacheEntry(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            timestamp: Date(),
            radius: radius,
            stopHeadsigns: stopHeadsigns,
            lastAccessTime: Date()
        )

        // Add or update the entry
        cache.entries[key] = newEntry

        // Implement LRU eviction: keep only the maxCachedLocations most recently used
        if cache.entries.count > maxCachedLocations {
            // Sort by last access time and remove the oldest ones
            let sortedEntries = cache.entries.sorted { $0.value.lastAccessTime > $1.value.lastAccessTime }
            let entriesToKeep = sortedEntries.prefix(maxCachedLocations)

            cache.entries = Dictionary(uniqueKeysWithValues: entriesToKeep.map { ($0.key, $0.value) })

            print("HeadsignCache: Evicted old entries, now caching \(cache.entries.count) locations")
        }

        saveMultiCache(cache)

        print("HeadsignCache: Saved cache with \(stopHeadsigns.count) stops at location (\(coordinate.latitude), \(coordinate.longitude))")
        print("HeadsignCache: Total cached locations: \(cache.entries.count)")
    }

    /// Clear all cached data
    func clearCache() {
        sharedDefaults?.removeObject(forKey: multiCacheKey)
        print("HeadsignCache: All location caches cleared")
    }

    /// Get cache information for debugging
    func getCacheInfo(currentLocation: CLLocation?) -> String {
        let cache = loadMultiCache()

        if cache.entries.isEmpty {
            return "No cached locations"
        }

        var info = "Cached locations: \(cache.entries.count)\n"

        for (key, entry) in cache.entries.sorted(by: { $0.value.lastAccessTime > $1.value.lastAccessTime }) {
            let age = Date().timeIntervalSince(entry.timestamp) / (24 * 60 * 60)
            let lastAccess = Date().timeIntervalSince(entry.lastAccessTime) / (24 * 60 * 60)

            var locationInfo = "Location (\(String(format: "%.3f", entry.latitude)), \(String(format: "%.3f", entry.longitude))): \(entry.stopHeadsigns.count) stops, age: \(String(format: "%.1f", age))d, last access: \(String(format: "%.1f", lastAccess))d ago"

            if let currentLocation = currentLocation {
                let entryLocation = CLLocation(latitude: entry.latitude, longitude: entry.longitude)
                let distance = currentLocation.distance(from: entryLocation)
                locationInfo += ", distance: \(Int(distance))m"
            }

            info += locationInfo + "\n"
        }

        return info
    }
}
