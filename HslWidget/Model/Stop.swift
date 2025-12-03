//
//  Stop.swift
//  HslWidget
//
//  Created by Francesco Balestrieri on 5.5.2024.
//

import Foundation

struct Stop: Identifiable, Codable, Equatable {

    let name: String
    let code: String
    let id: String
    let latitude: Double?
    let longitude: Double?
    let vehicleModes: Set<String>?
    let headsigns: [String]?
    let allStopIds: [String]? // All stop IDs that share this code (for multi-direction stops)
    let primaryMode: String? // The dominant transport mode based on route count

    // Filtering options
    let filteredLines: [String]? // If set, only show departures from these route short names
    let filteredHeadsignPattern: String? // If set, only show departures whose headsign contains this pattern

    /// Priority order for transport modes (higher index = higher priority)
    static let modePriority = ["BUS", "FERRY", "TRAM", "RAIL", "SUBWAY"]

    init(id: String, name: String, code: String, latitude: Double? = nil, longitude: Double? = nil, vehicleModes: Set<String>? = nil, headsigns: [String]? = nil, allStopIds: [String]? = nil, primaryMode: String? = nil, filteredLines: [String]? = nil, filteredHeadsignPattern: String? = nil) {
        self.id = id
        self.name = name
        self.code = code
        self.latitude = latitude
        self.longitude = longitude
        self.vehicleModes = vehicleModes
        self.headsigns = headsigns
        self.allStopIds = allStopIds
        self.primaryMode = primaryMode
        self.filteredLines = filteredLines
        self.filteredHeadsignPattern = filteredHeadsignPattern
    }

    /// Calculate primary mode from route counts - mode with most routes wins,
    /// ties broken by priority (SUBWAY > RAIL > TRAM > FERRY > BUS)
    static func calculatePrimaryMode(from routeCounts: [String: Int]) -> String? {
        guard !routeCounts.isEmpty else { return nil }

        let sorted = routeCounts.sorted { (a, b) in
            if a.value != b.value {
                return a.value > b.value // Higher count first
            }
            // Same count - use priority
            let priorityA = modePriority.firstIndex(of: a.key.uppercased()) ?? -1
            let priorityB = modePriority.firstIndex(of: b.key.uppercased()) ?? -1
            return priorityA > priorityB
        }

        return sorted.first?.key
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
