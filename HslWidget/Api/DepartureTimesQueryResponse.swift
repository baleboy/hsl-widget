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
        let realtimeDeparture: Double
        let serviceDay: Double
        let headsign: String?
        let trip: Trip
    }

    struct Trip: Codable {
        let route: Route
    }
    
    struct Route: Codable {
        let shortName: String
    }
    
    let data: Data
}
