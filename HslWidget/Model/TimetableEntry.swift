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

    /// Convenience computed property to check if widget has normal content
    var hasContent: Bool {
        state == .normal && !departures.isEmpty
    }

    static let example = TimetableEntry(
        date: Date(),
        stopName: "Merisotilaantori",
        departures: [
            Departure(departureTime: Date(), routeShortName: "4", headsign: "Munkkiniemi", mode: "TRAM"),
            Departure(departureTime: Date(), routeShortName: "550", headsign: "Munkkiniemi", mode: "BUS")
        ],
        state: .normal
    )

    static let example1Departure = TimetableEntry(
        date: Date(),
        stopName: "Merisotilaantori",
        departures: [
            Departure(departureTime: Date().addingTimeInterval(5 * 60), routeShortName: "4", headsign: "Munkkiniemi", mode: "TRAM")
        ],
        state: .normal
    )

    static let example2Departures = TimetableEntry(
        date: Date(),
        stopName: "Merisotilaantori",
        departures: [
            Departure(departureTime: Date().addingTimeInterval(5 * 60), routeShortName: "4", headsign: "Munkkiniemi", mode: "TRAM"),
            Departure(departureTime: Date().addingTimeInterval(12 * 60), routeShortName: "550H", headsign: "Kamppi", mode: "BUS")
        ],
        state: .normal
    )

    static let example3Departures = TimetableEntry(
        date: Date(),
        stopName: "Merisotilaantori",
        departures: [
            Departure(departureTime: Date().addingTimeInterval(5 * 60), routeShortName: "4", headsign: "Munkkiniemi", mode: "TRAM"),
            Departure(departureTime: Date().addingTimeInterval(12 * 60), routeShortName: "5", headsign: "Kamppi", mode: "TRAM"),
            Departure(departureTime: Date().addingTimeInterval(18 * 60), routeShortName: "7", headsign: "Töölö", mode: "TRAM")
        ],
        state: .normal
    )

    static let example4Departures = TimetableEntry(
        date: Date(),
        stopName: "Merisotilaantori",
        departures: [
            Departure(departureTime: Date().addingTimeInterval(3 * 60), routeShortName: "4", headsign: "Munkkiniemi", mode: "TRAM"),
            Departure(departureTime: Date().addingTimeInterval(8 * 60), routeShortName: "550", headsign: "Westendinasema", mode: "BUS"),
            Departure(departureTime: Date().addingTimeInterval(15 * 60), routeShortName: "7", headsign: "Töölö", mode: "TRAM"),
            Departure(departureTime: Date().addingTimeInterval(22 * 60), routeShortName: "4", headsign: "Katajanokka", mode: "TRAM")
        ],
        state: .normal
    )
}
