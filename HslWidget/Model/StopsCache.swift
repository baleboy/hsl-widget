//
//  StopsCache.swift
//  HslWidget
//
//  Manages persistent caching of the stops list to enable instant picker loading
//

import Foundation

class StopsCache {
    static let shared = StopsCache()

    private let sharedDefaults = UserDefaults(suiteName: "group.balenet.widget")
    private let cacheKey = "cachedStops"
    private let timestampKey = "cachedStopsTimestamp"
    private let cacheExpirationHours = 24

    private init() {}

    /// Load stops from cache synchronously
    /// Returns nil if cache is empty (first launch)
    func loadStops() -> [Stop]? {
        guard let data = sharedDefaults?.data(forKey: cacheKey),
              let stops = try? JSONDecoder().decode([Stop].self, from: data) else {
            print("StopsCache: No cached stops found")
            return nil
        }

        print("StopsCache: Loaded \(stops.count) stops from cache")
        return stops
    }

    /// Check if cache needs refresh (expired or empty)
    func needsRefresh() -> Bool {
        guard sharedDefaults?.data(forKey: cacheKey) != nil else {
            print("StopsCache: No cache exists, needs refresh")
            return true
        }

        guard let timestamp = sharedDefaults?.object(forKey: timestampKey) as? Date else {
            print("StopsCache: No timestamp found, needs refresh")
            return true
        }

        let hoursSinceCache = Date().timeIntervalSince(timestamp) / 3600
        let isExpired = hoursSinceCache > Double(cacheExpirationHours)

        if isExpired {
            print("StopsCache: Cache expired (\(String(format: "%.1f", hoursSinceCache)) hours old)")
        }

        return isExpired
    }

    /// Save stops to cache
    func saveStops(_ stops: [Stop]) {
        guard let data = try? JSONEncoder().encode(stops) else {
            print("StopsCache: Failed to encode stops")
            return
        }

        sharedDefaults?.set(data, forKey: cacheKey)
        sharedDefaults?.set(Date(), forKey: timestampKey)

        print("StopsCache: Saved \(stops.count) stops to cache")
    }

    /// Clear the cache
    func clearCache() {
        sharedDefaults?.removeObject(forKey: cacheKey)
        sharedDefaults?.removeObject(forKey: timestampKey)
        print("StopsCache: Cache cleared")
    }

    /// Get cache info for debugging
    func getCacheInfo() -> String {
        guard let timestamp = sharedDefaults?.object(forKey: timestampKey) as? Date else {
            return "No cache"
        }

        let hoursSinceCache = Date().timeIntervalSince(timestamp) / 3600
        let stops = loadStops()
        let count = stops?.count ?? 0

        return "Cached \(count) stops, age: \(String(format: "%.1f", hoursSinceCache)) hours"
    }
}
