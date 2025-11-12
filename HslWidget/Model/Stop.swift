//
//  Stop.swift
//  HslWidget
//
//  Created by Francesco Balestrieri on 5.5.2024.
//

import Foundation

struct Stop: Identifiable, Codable {

    let name: String
    let code: String
    let id: String
    let latitude: Double?
    let longitude: Double?
    let vehicleModes: Set<String>?
    let headsigns: [String]?
    let allStopIds: [String]? // All stop IDs that share this code (for multi-direction stops)

    init(id: String, name: String, code: String, latitude: Double? = nil, longitude: Double? = nil, vehicleModes: Set<String>? = nil, headsigns: [String]? = nil, allStopIds: [String]? = nil) {
        self.id = id
        self.name = name
        self.code = code
        self.latitude = latitude
        self.longitude = longitude
        self.vehicleModes = vehicleModes
        self.headsigns = headsigns
        self.allStopIds = allStopIds
    }

    static var defaultStop: Stop {
        Stop(id: "HSL:1080416", name: "Merisotilaantori", code: "H0421", latitude: 60.159, longitude: 24.9208, vehicleModes: ["TRAM"])
    }
}
