//
//  GraphQLResponse.swift
//  HslWidget
//
//  Created by Francesco Balestrieri on 5.5.2024.
//

import Foundation

struct DepartureTimesQueryResponse: Codable {
    
    struct Data: Codable {
        let stop: Stop
    }

    struct Stop: Codable {
        let stoptimesWithoutPatterns: [Stoptime]
    }
    
    struct Stoptime: Codable {
        let scheduledDeparture: Double
        let realtimeDeparture: Double
        let serviceDay: Double
        let departureDelay: Int
        let headsign: String?
        let stop: StoptimeStop?
        let trip: Trip
    }

    struct StoptimeStop: Codable {
        let platformCode: String?
    }

    struct Trip: Codable {
        let route: Route
    }
    
    struct Route: Codable {
        let shortName: String
        let mode: String
    }
    
    let data: Data
}

// Simplified response model for headsigns-only queries
struct HeadsignsQueryResponse: Codable {

    struct Data: Codable {
        let stop: Stop
    }

    struct Stop: Codable {
        let stoptimesWithoutPatterns: [Stoptime]
    }

    struct Stoptime: Codable {
        let headsign: String?
    }

    let data: Data
}
