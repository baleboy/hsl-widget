//
//  Departure.swift
//  HslWidget
//
//  Created by Francesco Balestrieri on 5.5.2024.
//

import Foundation

struct Departure: Identifiable {
    let id: UUID
    let departureTime: Date // Scheduled departure time (shown in UI)
    let routeShortName: String
    let headsign: String
    let mode: String? // Transportation mode (BUS, TRAM, etc.)
    let delaySeconds: Int // Delay in seconds (negative = early, positive = late)
    let realtimeDepartureTime: Date // Actual predicted departure time (for timeline calculations)
    let platformCode: String? // Platform code (for trains and metro)

    // Debug fields (optional, only populated for debug views)
    let hasRealtimeData: Bool
    let realtimeState: String?
    let serviceDay: Double?

    init(id: UUID = UUID(), departureTime: Date, routeShortName: String, headsign: String, mode: String? = nil, delaySeconds: Int = 0, realtimeDepartureTime: Date? = nil, platformCode: String? = nil, hasRealtimeData: Bool = false, realtimeState: String? = nil, serviceDay: Double? = nil) {
        self.id = id
        self.departureTime = departureTime
        self.routeShortName = routeShortName
        self.headsign = headsign
        self.mode = mode
        self.delaySeconds = delaySeconds
        // If realtime not provided, calculate it from scheduled + delay
        self.realtimeDepartureTime = realtimeDepartureTime ?? departureTime.addingTimeInterval(Double(delaySeconds))
        self.platformCode = platformCode
        self.hasRealtimeData = hasRealtimeData
        self.realtimeState = realtimeState
        self.serviceDay = serviceDay
    }

    /// Delay in minutes (rounded)
    var delayMinutes: Int {
        return Int(round(Double(delaySeconds) / 60.0))
    }

    /// Whether to show delay (only if >= 2 minutes late)
    var shouldShowDelay: Bool {
        return delayMinutes >= 2
    }
}
