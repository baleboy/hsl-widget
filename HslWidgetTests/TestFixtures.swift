//
//  TestFixtures.swift
//  HslWidgetTests
//
//  Shared test data and fixtures for unit tests
//

import Foundation
@testable import HslWidget

/// Provides reusable test data for unit tests
struct TestFixtures {

    // MARK: - Stops

    static let stop1 = Stop(
        id: "HSL:1234",
        name: "Merisotilaantori",
        code: "H1234",
        latitude: 60.159,
        longitude: 24.9208,
        vehicleModes: ["TRAM", "BUS"]
    )

    static let stop2 = Stop(
        id: "HSL:5678",
        name: "Kamppi",
        code: "H5678",
        latitude: 60.168,
        longitude: 24.931,
        vehicleModes: ["BUS", "METRO"]
    )

    static let stop3 = Stop(
        id: "HSL:9999",
        name: "Töölö",
        code: "H9999",
        latitude: 60.175,
        longitude: 24.925,
        vehicleModes: ["TRAM"]
    )

    static let stopWithLineFilter = Stop(
        id: "HSL:1111",
        name: "Filtered Stop",
        code: "H1111",
        latitude: 60.159,
        longitude: 24.9208,
        filteredLines: ["4", "7"]
    )

    static let stopWithHeadsignFilter = Stop(
        id: "HSL:2222",
        name: "Headsign Filtered Stop",
        code: "H2222",
        latitude: 60.159,
        longitude: 24.9208,
        filteredHeadsignPattern: "Munkki"
    )

    static let stopWithBothFilters = Stop(
        id: "HSL:3333",
        name: "Both Filters Stop",
        code: "H3333",
        latitude: 60.159,
        longitude: 24.9208,
        filteredLines: ["4"],
        filteredHeadsignPattern: "Munkki"
    )

    // MARK: - Departures

    static func departure(
        minutesFromNow: Double,
        route: String = "4",
        headsign: String = "Munkkiniemi",
        mode: String = "TRAM"
    ) -> Departure {
        Departure(
            departureTime: Date().addingTimeInterval(minutesFromNow * 60),
            routeShortName: route,
            headsign: headsign,
            mode: mode
        )
    }

    static let departures = [
        departure(minutesFromNow: 2, route: "4", headsign: "Munkkiniemi"),
        departure(minutesFromNow: 5, route: "7", headsign: "Töölö"),
        departure(minutesFromNow: 8, route: "550", headsign: "Westendinasema", mode: "BUS"),
        departure(minutesFromNow: 12, route: "4", headsign: "Katajanokka"),
        departure(minutesFromNow: 15, route: "7", headsign: "Töölö"),
        departure(minutesFromNow: 20, route: "4", headsign: "Munkkiniemi"),
    ]

    static let pastDepartures = [
        departure(minutesFromNow: -10, route: "4", headsign: "Munkkiniemi"),
        departure(minutesFromNow: -5, route: "7", headsign: "Töölö"),
        departure(minutesFromNow: 2, route: "550", headsign: "Westendinasema", mode: "BUS"),
        departure(minutesFromNow: 5, route: "4", headsign: "Katajanokka"),
    ]

    // MARK: - API Response JSON

    static let stopsResponseJSON = """
    {
        "data": {
            "stops": [
                {
                    "gtfsId": "HSL:1234",
                    "name": "Merisotilaantori",
                    "code": "H1234",
                    "lat": 60.159,
                    "lon": 24.9208,
                    "routes": [
                        { "mode": "TRAM" },
                        { "mode": "BUS" }
                    ]
                },
                {
                    "gtfsId": "HSL:5678",
                    "name": "Kamppi",
                    "code": "H5678",
                    "lat": 60.168,
                    "lon": 24.931,
                    "routes": [
                        { "mode": "BUS" }
                    ]
                }
            ]
        }
    }
    """

    static let departuresResponseJSON = """
    {
        "data": {
            "stop": {
                "stoptimesWithoutPatterns": [
                    {
                        "serviceDay": 1700000000,
                        "scheduledDeparture": 3600,
                        "realtimeDeparture": 3600,
                        "realtime": true,
                        "realtimeState": "UPDATED",
                        "departureDelay": 0,
                        "headsign": "Munkkiniemi",
                        "trip": {
                            "route": {
                                "mode": "TRAM",
                                "shortName": "4"
                            }
                        }
                    },
                    {
                        "serviceDay": 1700000000,
                        "scheduledDeparture": 7200,
                        "realtimeDeparture": 7200,
                        "realtime": true,
                        "realtimeState": "UPDATED",
                        "departureDelay": 0,
                        "headsign": "Kamppi",
                        "trip": {
                            "route": {
                                "mode": "BUS",
                                "shortName": "550"
                            }
                        }
                    }
                ]
            }
        }
    }
    """

    static let headsignsResponseJSON = """
    {
        "data": {
            "stop": {
                "stoptimesWithoutPatterns": [
                    { "headsign": "Munkkiniemi" },
                    { "headsign": "Katajanokka" },
                    { "headsign": "Munkkiniemi" },
                    { "headsign": "Töölö" }
                ]
            }
        }
    }
    """

    // MARK: - Helper Functions

    /// Creates a date at a specific time offset from now
    static func date(minutesFromNow: Double) -> Date {
        Date().addingTimeInterval(minutesFromNow * 60)
    }

    /// Creates an array of departures with specified minute offsets
    static func departures(minuteOffsets: [Double], route: String = "4") -> [Departure] {
        minuteOffsets.map { offset in
            departure(minutesFromNow: offset, route: route)
        }
    }
}
