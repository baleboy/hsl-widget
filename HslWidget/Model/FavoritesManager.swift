//
//  FavoritesManager.swift
//  HslWidget
//
//  Manages favorite stops storage using App Group UserDefaults
//

import Foundation
import WidgetKit

class FavoritesManager {
    static let shared = FavoritesManager()

    private let sharedDefaults = UserDefaults(suiteName: "group.balenet.widget")
    private let favoritesKey = "favoriteStops"

    private init() {}

    /// Get all favorite stops
    func getFavorites() -> [Stop] {
        guard let data = sharedDefaults?.data(forKey: favoritesKey),
              let stops = try? JSONDecoder().decode([Stop].self, from: data) else {
            print("FavoritesManager: No favorites found or decode failed")
            return []
        }
        print("FavoritesManager: Loaded \(stops.count) favorites: \(stops.map { $0.name })")
        return stops
    }

    /// Add a stop to favorites
    func addFavorite(_ stop: Stop) {
        var favorites = getFavorites()

        // Don't add duplicates
        if favorites.contains(where: { $0.id == stop.id }) {
            return
        }

        favorites.append(stop)
        saveFavorites(favorites)
    }

    /// Remove a stop from favorites
    func removeFavorite(_ stop: Stop) {
        var favorites = getFavorites()
        favorites.removeAll { $0.id == stop.id }
        saveFavorites(favorites)
    }

    /// Toggle favorite status of a stop
    func toggleFavorite(_ stop: Stop) {
        if isFavorite(stop) {
            removeFavorite(stop)
        } else {
            addFavorite(stop)
        }
    }

    /// Check if a stop is in favorites
    func isFavorite(_ stop: Stop) -> Bool {
        return getFavorites().contains(where: { $0.id == stop.id })
    }

    /// Update an existing favorite stop (e.g., to change filters)
    func updateFavorite(_ stop: Stop) {
        var favorites = getFavorites()

        // Find and replace the stop with matching ID
        if let index = favorites.firstIndex(where: { $0.id == stop.id }) {
            favorites[index] = stop
            saveFavorites(favorites)
            print("FavoritesManager: Updated favorite: \(stop.name)")
        } else {
            print("FavoritesManager: Warning - tried to update non-existent favorite: \(stop.name)")
        }
    }

    /// Save favorites to UserDefaults
    private func saveFavorites(_ favorites: [Stop]) {
        if let encoded = try? JSONEncoder().encode(favorites) {
            sharedDefaults?.set(encoded, forKey: favoritesKey)
            print("FavoritesManager: Saved \(favorites.count) favorites: \(favorites.map { $0.name })")

            // Reload widget timelines when favorites change
            WidgetCenter.shared.reloadAllTimelines()
        } else {
            print("FavoritesManager: Failed to encode favorites")
        }
    }
}
