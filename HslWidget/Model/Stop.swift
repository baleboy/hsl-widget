//
//  Stop.swift
//  HslWidget
//
//  Created by Francesco Balestrieri on 5.5.2024.
//

import Foundation

struct Stop: Identifiable, Codable, Equatable, Hashable {

    let name: String
    let code: String
    let id: String
    let latitude: Double?
    let longitude: Double?
    let vehicleModes: Set<String>?
    let headsigns: [String]?
    let allStopIds: [String]? // All stop IDs that share this code (for multi-direction stops)

    // Filtering options
    let filteredLines: [String]? // If set, only show departures from these route short names
    let filteredHeadsignPattern: String? // If set, only show departures whose headsign contains this pattern

    init(id: String, name: String, code: String, latitude: Double? = nil, longitude: Double? = nil, vehicleModes: Set<String>? = nil, headsigns: [String]? = nil, allStopIds: [String]? = nil, filteredLines: [String]? = nil, filteredHeadsignPattern: String? = nil) {
        self.id = id
        self.name = name
        self.code = code
        self.latitude = latitude
        self.longitude = longitude
        self.vehicleModes = vehicleModes
        self.headsigns = headsigns
        self.allStopIds = allStopIds
        self.filteredLines = filteredLines
        self.filteredHeadsignPattern = filteredHeadsignPattern
    }

    static var defaultStop: Stop {
        Stop(id: "HSL:1080416", name: "Merisotilaantori", code: "H0421", latitude: 60.159, longitude: 24.9208, vehicleModes: ["TRAM"])
    }

    /// Check if a departure matches this stop's filters
    /// Returns true if the departure should be shown based on the configured filters
    func matchesFilters(departure: Departure) -> Bool {
        // Check line filter
        if let filteredLines = filteredLines, !filteredLines.isEmpty {
            if !filteredLines.contains(departure.routeShortName) {
                return false
            }
        }

        // Check headsign filter
        if let pattern = filteredHeadsignPattern, !pattern.isEmpty {
            if !departure.headsign.localizedCaseInsensitiveContains(pattern) {
                return false
            }
        }

        return true
    }

    /// Returns true if any filters are configured
    var hasFilters: Bool {
        return (filteredLines != nil && !filteredLines!.isEmpty) ||
               (filteredHeadsignPattern != nil && !filteredHeadsignPattern!.isEmpty)
    }
}
