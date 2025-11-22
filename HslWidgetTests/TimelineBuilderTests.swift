//
//  TimelineBuilderTests.swift
//  HslWidgetTests
//
//  Unit tests for timeline building logic
//
//  Note: TimelineBuilder is in the widget extension and has complex dependencies.
//  These tests verify the core logic patterns used by TimelineBuilder.
//  For full TimelineBuilder testing, consider refactoring for dependency injection.
//

import XCTest
import CoreLocation
@testable import HslWidget

final class TimelineBuilderTests: XCTestCase {

    // MARK: - Departure Filtering Logic Tests

    func testFiltersPastDepartures() {
        // Given: Mix of past and future departures
        let now = Date()
        let departures = [
            TestFixtures.departure(minutesFromNow: -10),
            TestFixtures.departure(minutesFromNow: -5),
            TestFixtures.departure(minutesFromNow: 2),
            TestFixtures.departure(minutesFromNow: 5),
        ]

        // When: Filtering to future only
        let futureDepartures = departures.filter { $0.departureTime > now }

        // Then: Only future departures should be included
        XCTAssertEqual(futureDepartures.count, 2)
        XCTAssertTrue(futureDepartures.allSatisfy { $0.departureTime > now })
    }

    func testSortsDeparturesByTime() {
        // Given: Unsorted departures
        let departures = [
            TestFixtures.departure(minutesFromNow: 15),
            TestFixtures.departure(minutesFromNow: 2),
            TestFixtures.departure(minutesFromNow: 8),
        ]

        // When: Sorting by departure time
        let sorted = departures.sorted { $0.departureTime < $1.departureTime }

        // Then: Should be in chronological order
        XCTAssertEqual(sorted[0].departureTime.timeIntervalSince1970, departures[1].departureTime.timeIntervalSince1970, accuracy: 1.0)
        XCTAssertEqual(sorted[1].departureTime.timeIntervalSince1970, departures[2].departureTime.timeIntervalSince1970, accuracy: 1.0)
        XCTAssertEqual(sorted[2].departureTime.timeIntervalSince1970, departures[0].departureTime.timeIntervalSince1970, accuracy: 1.0)
    }

    // MARK: - Closest Stop Selection Tests

    func testClosestStop_WithLocation() {
        // Given: Multiple favorites and a location
        let favorites = [
            Stop(id: "HSL:1", name: "Far Stop", code: "H1",
                 latitude: 60.1, longitude: 24.8),
            Stop(id: "HSL:2", name: "Close Stop", code: "H2",
                 latitude: 60.159, longitude: 24.9208),
            Stop(id: "HSL:3", name: "Medium Stop", code: "H3",
                 latitude: 60.15, longitude: 24.9),
        ]

        let currentLocation = CLLocation(latitude: 60.16, longitude: 24.92)

        // When: Finding closest stop
        let closest = findClosestStop(
            favorites: favorites,
            currentLocation: currentLocation
        )

        // Then: Should return the geographically closest stop
        XCTAssertEqual(closest.id, "HSL:2")
        XCTAssertEqual(closest.name, "Close Stop")
    }

    func testClosestStop_WithoutLocation_ReturnsFirstAlphabetically() {
        // Given: Multiple favorites, no location
        let favorites = [
            Stop(id: "HSL:1", name: "Zebra", code: "H1"),
            Stop(id: "HSL:2", name: "Alpha", code: "H2"),
            Stop(id: "HSL:3", name: "Bravo", code: "H3"),
        ]

        // When: Finding closest stop without location
        let closest = findClosestStop(
            favorites: favorites,
            currentLocation: nil
        )

        // Then: Should return first alphabetically
        XCTAssertEqual(closest.name, "Alpha")
    }

    // MARK: - Filter Integration Tests

    func testAppliesStopFilters() {
        // Given: Stop with line filter
        let stop = TestFixtures.stopWithLineFilter
        let departures = [
            TestFixtures.departure(minutesFromNow: 5, route: "4"),
            TestFixtures.departure(minutesFromNow: 8, route: "550"),
            TestFixtures.departure(minutesFromNow: 12, route: "7"),
        ]

        // When: Filtering departures
        let filtered = departures.filter { stop.matchesFilters(departure: $0) }

        // Then: Should only include filtered lines (4, 7)
        XCTAssertEqual(filtered.count, 2)
        XCTAssertTrue(filtered.contains { $0.routeShortName == "4" })
        XCTAssertTrue(filtered.contains { $0.routeShortName == "7" })
        XCTAssertFalse(filtered.contains { $0.routeShortName == "550" })
    }

    // MARK: - Helper Methods

    /// Helper to find closest stop (mirrors TimelineBuilder logic)
    private func findClosestStop(
        favorites: [Stop],
        currentLocation: CLLocation?
    ) -> Stop {
        guard let currentLocation = currentLocation else {
            return favorites.sorted(by: { $0.name < $1.name }).first!
        }

        var closestStop = favorites[0]
        var minDistance = Double.greatestFiniteMagnitude

        for stop in favorites {
            if let lat = stop.latitude, let lon = stop.longitude {
                let stopLocation = CLLocation(latitude: lat, longitude: lon)
                let distance = currentLocation.distance(from: stopLocation)

                if distance < minDistance {
                    minDistance = distance
                    closestStop = stop
                }
            }
        }

        return closestStop
    }
}
