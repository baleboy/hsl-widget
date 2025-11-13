//
//  HeadsignCache.swift
//  HslWidget
//
//  Manages persistent caching of headsigns with location-based expiration
//

import Foundation
import CoreLocation

class HeadsignCache {
    static let shared = HeadsignCache()

    private let sharedDefaults = UserDefaults(suiteName: "group.balenet.widget")

    private let cacheKey = "headsignsCache"
    private let cacheLocationLatKey = "headsignsCacheLatitude"
    private let cacheLocationLonKey = "headsignsCacheLongitude"
    private let cacheTimestampKey = "headsignsCacheTimestamp"
    private let cacheRadiusKey = "headsignsCacheRadius"

    private let cacheExpirationDays = 7 // Refresh weekly
    private let cacheLocationThresholdMeters = 2000.0 // Invalidate if user moves >2km

    struct CachedHeadsigns: Codable {
        let stopHeadsigns: [String: [String]] // stopId -> headsigns
    }

    private init() {}

    /// Check if cache should be refreshed based on time and location
    func shouldRefreshCache(currentLocation: CLLocation?, radius: Double = 5000) -> Bool {
        // No cache exists
        guard let timestamp = sharedDefaults?.object(forKey: cacheTimestampKey) as? Date else {
            print("HeadsignCache: No cache timestamp found, needs refresh")
            return true
        }

        // Check if cache is too old
        let daysSinceCache = Date().timeIntervalSince(timestamp) / (24 * 60 * 60)
        if daysSinceCache > Double(cacheExpirationDays) {
            print("HeadsignCache: Cache is \(Int(daysSinceCache)) days old, needs refresh")
            return true
        }

        // Check if user location has changed significantly
        if let currentLocation = currentLocation,
           let cachedLat = sharedDefaults?.double(forKey: cacheLocationLatKey),
           let cachedLon = sharedDefaults?.double(forKey: cacheLocationLonKey),
           cachedLat != 0 && cachedLon != 0 {

            let cachedLocation = CLLocation(latitude: cachedLat, longitude: cachedLon)
            let distance = currentLocation.distance(from: cachedLocation)

            if distance > cacheLocationThresholdMeters {
                print("HeadsignCache: User moved \(Int(distance))m from cached location, needs refresh")
                return true
            }
        }

        // Check if radius has changed
        if let cachedRadius = sharedDefaults?.double(forKey: cacheRadiusKey), cachedRadius != radius {
            print("HeadsignCache: Radius changed from \(cachedRadius)m to \(radius)m, needs refresh")
            return true
        }

        print("HeadsignCache: Cache is valid (age: \(String(format: "%.1f", daysSinceCache)) days)")
        return false
    }

    /// Load cached headsigns
    func loadCache() -> [String: [String]]? {
        guard let data = sharedDefaults?.data(forKey: cacheKey),
              let cached = try? JSONDecoder().decode(CachedHeadsigns.self, from: data) else {
            print("HeadsignCache: No valid cache found")
            return nil
        }

        print("HeadsignCache: Loaded cache with \(cached.stopHeadsigns.count) stops")
        return cached.stopHeadsigns
    }

    /// Save headsigns to cache with location and timestamp
    func saveCache(_ stopHeadsigns: [String: [String]], location: CLLocation?, radius: Double) {
        let cached = CachedHeadsigns(stopHeadsigns: stopHeadsigns)

        guard let data = try? JSONEncoder().encode(cached) else {
            print("HeadsignCache: Failed to encode cache")
            return
        }

        sharedDefaults?.set(data, forKey: cacheKey)
        sharedDefaults?.set(Date(), forKey: cacheTimestampKey)
        sharedDefaults?.set(radius, forKey: cacheRadiusKey)

        if let location = location {
            sharedDefaults?.set(location.coordinate.latitude, forKey: cacheLocationLatKey)
            sharedDefaults?.set(location.coordinate.longitude, forKey: cacheLocationLonKey)
            print("HeadsignCache: Saved cache with \(stopHeadsigns.count) stops at location (\(location.coordinate.latitude), \(location.coordinate.longitude))")
        } else {
            print("HeadsignCache: Saved cache with \(stopHeadsigns.count) stops (no location)")
        }
    }

    /// Clear all cached data
    func clearCache() {
        sharedDefaults?.removeObject(forKey: cacheKey)
        sharedDefaults?.removeObject(forKey: cacheTimestampKey)
        sharedDefaults?.removeObject(forKey: cacheLocationLatKey)
        sharedDefaults?.removeObject(forKey: cacheLocationLonKey)
        sharedDefaults?.removeObject(forKey: cacheRadiusKey)
        print("HeadsignCache: Cache cleared")
    }

    /// Get cache age in days
    func getCacheAge() -> Double? {
        guard let timestamp = sharedDefaults?.object(forKey: cacheTimestampKey) as? Date else {
            return nil
        }
        return Date().timeIntervalSince(timestamp) / (24 * 60 * 60)
    }
}
