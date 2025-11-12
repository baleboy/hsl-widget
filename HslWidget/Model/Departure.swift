//
//  Departure.swift
//  HslWidget
//
//  Created by Francesco Balestrieri on 5.5.2024.
//

import Foundation

struct Departure: Identifiable {
    let id: UUID
    let departureTime: Date
    let routeShortName: String
    let headsign: String
    let mode: String? // Transportation mode (BUS, TRAM, etc.)

    init(id: UUID = UUID(), departureTime: Date, routeShortName: String, headsign: String, mode: String? = nil) {
        self.id = id
        self.departureTime = departureTime
        self.routeShortName = routeShortName
        self.headsign = headsign
        self.mode = mode
    }
}
