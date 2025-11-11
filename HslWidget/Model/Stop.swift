//
//  Stop.swift
//  HslWidget
//
//  Created by Francesco Balestrieri on 5.5.2024.
//

import CoreLocation
import Foundation

struct Stop: Identifiable, Codable {

    let name: String
    let code: String
    let id: String
    let latitude: Double
    let longitude: Double

    init(id: String, name: String, code: String, latitude: Double, longitude: Double) {
        self.id = id
        self.name = name
        self.code = code
        self.latitude = latitude
        self.longitude = longitude
    }

    static var defaultStop: Stop {
        Stop(
            id: "HSL:1080416",
            name: "Merisotilaantori",
            code: "H0421",
            latitude: 60.1497,
            longitude: 24.9627
        )
    }

    func distance(from location: CLLocation) -> CLLocationDistance {
        let stopLocation = CLLocation(latitude: latitude, longitude: longitude)
        return stopLocation.distance(from: location)
    }
}

enum FavoriteStopsStore {
    private static let favoritesKey = "favoriteStops"
    private static let legacyIdKey = "selectedStopId"
    private static let legacyNameKey = "selectedStopName"

    static func load(from defaults: UserDefaults?) -> [Stop] {
        guard let defaults else { return [] }

        if let data = defaults.data(forKey: favoritesKey),
           let stops = try? JSONDecoder().decode([Stop].self, from: data) {
            return stops
        }

        return []
    }

    static func save(_ stops: [Stop], to defaults: UserDefaults?) {
        guard let defaults else { return }
        guard let data = try? JSONEncoder().encode(stops) else { return }
        defaults.set(data, forKey: favoritesKey)
        defaults.removeObject(forKey: legacyIdKey)
        defaults.removeObject(forKey: legacyNameKey)
    }

    static func loadLegacyStop(from defaults: UserDefaults?) -> Stop? {
        guard let defaults,
              let id = defaults.string(forKey: legacyIdKey),
              let name = defaults.string(forKey: legacyNameKey) else {
            return nil
        }

        return Stop(id: id, name: name, code: "", latitude: 0, longitude: 0)
    }
}
