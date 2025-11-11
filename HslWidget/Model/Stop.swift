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

    init(id: String, name: String, code: String, latitude: Double? = nil, longitude: Double? = nil) {
        self.id = id
        self.name = name
        self.code = code
        self.latitude = latitude
        self.longitude = longitude
    }

    static var defaultStop: Stop {
        Stop(id: "HSL:1080416", name: "Merisotilaantori", code: "H0421", latitude: 60.159, longitude: 24.9208)
    }
}
