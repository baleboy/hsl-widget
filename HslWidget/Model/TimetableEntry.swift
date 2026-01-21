//
//  TimetableEntry.swift
//  stopInfo
//
//  Created by Claude Code
//

import WidgetKit
import Foundation

struct TimetableEntry: TimelineEntry {
    enum WidgetState {
        case normal
        case noFavorites
        case noDepartures
    }

    let date: Date
    let stopName: String
    let departures: [Departure]
    let state: WidgetState
    let useRealtimeDepartures: Bool

    /// Convenience computed property to check if widget has normal content
    var hasContent: Bool {
        state == .normal && !departures.isEmpty
    }

    /// Returns the appropriate display time for a departure based on settings
    func displayTime(for departure: Departure) -> Date {
        useRealtimeDepartures ? departure.realtimeDepartureTime : departure.departureTime
    }

    static let example = TimetableEntry(
        date: Date(),
        stopName: "Merisotilaantori",
        departures: [
            Departure(departureTime: Date(), routeShortName: "4", headsign: "Munkkiniemi", mode: "TRAM", delaySeconds: 180),
            Departure(departureTime: Date(), routeShortName: "550", headsign: "Munkkiniemi", mode: "BUS")
        ],
        state: .normal,
        useRealtimeDepartures: false
    )

    static let example1Departure = TimetableEntry(
        date: Date(),
        stopName: "Merisotilaantori",
        departures: [
            Departure(departureTime: Date().addingTimeInterval(5 * 60), routeShortName: "4", headsign: "Munkkiniemi", mode: "TRAM", delaySeconds: 300)
        ],
        state: .normal,
        useRealtimeDepartures: false
    )

    static let example2Departures = TimetableEntry(
        date: Date(),
        stopName: "Helsinki Central Station",
        departures: [
            Departure(departureTime: Date().addingTimeInterval(5 * 60), routeShortName: "I", headsign: "Tampere", mode: "RAIL", delaySeconds: 180, platformCode: "7"),
            Departure(departureTime: Date().addingTimeInterval(12 * 60), routeShortName: "R", headsign: "Riihimäki", mode: "RAIL", platformCode: "3")
        ],
        state: .normal,
        useRealtimeDepartures: false
    )

    static let example3Departures = TimetableEntry(
        date: Date(),
        stopName: "Merisotilaantori",
        departures: [
            Departure(departureTime: Date().addingTimeInterval(5 * 60), routeShortName: "4", headsign: "Munkkiniemi", mode: "TRAM"),
            Departure(departureTime: Date().addingTimeInterval(12 * 60), routeShortName: "5", headsign: "Kamppi", mode: "TRAM", delaySeconds: 240),
            Departure(departureTime: Date().addingTimeInterval(18 * 60), routeShortName: "7", headsign: "Töölö", mode: "TRAM")
        ],
        state: .normal,
        useRealtimeDepartures: false
    )

    static let example4Departures = TimetableEntry(
        date: Date(),
        stopName: "Helsinki Central Station",
        departures: [
            Departure(departureTime: Date().addingTimeInterval(3 * 60), routeShortName: "P", headsign: "Turku", mode: "RAIL", delaySeconds: 240, platformCode: "9"),
            Departure(departureTime: Date().addingTimeInterval(8 * 60), routeShortName: "I", headsign: "Tampere", mode: "RAIL", platformCode: "7"),
            Departure(departureTime: Date().addingTimeInterval(15 * 60), routeShortName: "R", headsign: "Riihimäki", mode: "RAIL", delaySeconds: 180, platformCode: "3"),
            Departure(departureTime: Date().addingTimeInterval(22 * 60), routeShortName: "S", headsign: "Kouvola", mode: "RAIL", platformCode: "11")
        ],
        state: .normal,
        useRealtimeDepartures: false
    )
}
