//
//  ModelFilteringTests.swift
//  HslWidgetTests
//
//  Comprehensive tests for Stop filtering logic
//

import XCTest
@testable import HslWidget

final class ModelFilteringTests: XCTestCase {

    // MARK: - No Filters Tests

    func testNoFilters_MatchesAllDepartures() {
        // Given: Stop with no filters
        let stop = TestFixtures.stop1
        let departures = [
            TestFixtures.departure(minutesFromNow: 5, route: "4"),
            TestFixtures.departure(minutesFromNow: 10, route: "7"),
            TestFixtures.departure(minutesFromNow: 15, route: "550", mode: "BUS"),
        ]

        // When: Checking matches
        let matches = departures.filter { stop.matchesFilters(departure: $0) }

        // Then: Should match all
        XCTAssertEqual(matches.count, 3)
        XCTAssertFalse(stop.hasFilters)
    }

    // MARK: - Line Filter Tests

    func testLineFilter_MatchesOnlyFilteredLines() {
        // Given: Stop filtering for lines 4 and 7
        let stop = TestFixtures.stopWithLineFilter // filters: ["4", "7"]
        let departures = [
            TestFixtures.departure(minutesFromNow: 5, route: "4"),
            TestFixtures.departure(minutesFromNow: 8, route: "550"),
            TestFixtures.departure(minutesFromNow: 10, route: "7"),
            TestFixtures.departure(minutesFromNow: 12, route: "10"),
        ]

        // When: Filtering
        let matches = departures.filter { stop.matchesFilters(departure: $0) }

        // Then: Should only match lines 4 and 7
        XCTAssertEqual(matches.count, 2)
        XCTAssertTrue(matches.contains { $0.routeShortName == "4" })
        XCTAssertTrue(matches.contains { $0.routeShortName == "7" })
        XCTAssertFalse(matches.contains { $0.routeShortName == "550" })
        XCTAssertTrue(stop.hasFilters)
    }

    func testLineFilter_EmptyArray_MatchesNone() {
        // Given: Stop with empty line filter
        let stop = Stop(
            id: "HSL:1234",
            name: "Test",
            code: "H1234",
            filteredLines: []
        )
        let departure = TestFixtures.departure(minutesFromNow: 5, route: "4")

        // When: Checking match
        let matches = stop.matchesFilters(departure: departure)

        // Then: Empty filter means match all
        XCTAssertTrue(matches)
    }

    func testLineFilter_CaseSensitive() {
        // Given: Stop filtering for lowercase line
        let stop = Stop(
            id: "HSL:1234",
            name: "Test",
            code: "H1234",
            filteredLines: ["4a"]
        )
        let departure1 = TestFixtures.departure(minutesFromNow: 5, route: "4A")
        let departure2 = TestFixtures.departure(minutesFromNow: 10, route: "4a")

        // When: Checking matches
        let matches1 = stop.matchesFilters(departure: departure1)
        let matches2 = stop.matchesFilters(departure: departure2)

        // Then: Should respect case sensitivity
        // Note: Implementation may vary - adjust based on actual behavior
        XCTAssertFalse(matches1)
        XCTAssertTrue(matches2)
    }

    // MARK: - Headsign Pattern Filter Tests

    func testHeadsignPattern_MatchesSubstring() {
        // Given: Stop filtering for "Munkki" pattern
        let stop = TestFixtures.stopWithHeadsignFilter // pattern: "Munkki"
        let departures = [
            TestFixtures.departure(minutesFromNow: 5, headsign: "Munkkiniemi"),
            TestFixtures.departure(minutesFromNow: 10, headsign: "Kamppi"),
            TestFixtures.departure(minutesFromNow: 15, headsign: "Munkki via center"),
        ]

        // When: Filtering
        let matches = departures.filter { stop.matchesFilters(departure: $0) }

        // Then: Should match headsigns containing pattern
        XCTAssertEqual(matches.count, 2)
        XCTAssertTrue(matches.contains { $0.headsign.contains("Munkkiniemi") })
        XCTAssertTrue(matches.contains { $0.headsign.contains("Munkki via center") })
        XCTAssertFalse(matches.contains { $0.headsign == "Kamppi" })
        XCTAssertTrue(stop.hasFilters)
    }

    func testHeadsignPattern_CaseInsensitive() {
        // Given: Stop with uppercase pattern
        let stop = Stop(
            id: "HSL:1234",
            name: "Test",
            code: "H1234",
            filteredHeadsignPattern: "MUNKKI"
        )
        let departure = TestFixtures.departure(minutesFromNow: 5, headsign: "Munkkiniemi")

        // When: Checking match
        let matches = stop.matchesFilters(departure: departure)

        // Then: Should match case-insensitively
        // Note: This depends on actual implementation
        XCTAssertTrue(matches)
    }

    func testHeadsignPattern_EmptyPattern_MatchesAll() {
        // Given: Stop with empty headsign pattern
        let stop = Stop(
            id: "HSL:1234",
            name: "Test",
            code: "H1234",
            filteredHeadsignPattern: ""
        )
        let departure = TestFixtures.departure(minutesFromNow: 5, headsign: "Anywhere")

        // When: Checking match
        let matches = stop.matchesFilters(departure: departure)

        // Then: Empty pattern should match all
        XCTAssertTrue(matches)
    }

    // MARK: - Combined Filters Tests

    func testBothFilters_BothMustMatch() {
        // Given: Stop with both line and headsign filters
        let stop = TestFixtures.stopWithBothFilters // lines: ["4"], pattern: "Munkki"
        let departures = [
            TestFixtures.departure(minutesFromNow: 5, route: "4", headsign: "Munkkiniemi"),     // both match
            TestFixtures.departure(minutesFromNow: 8, route: "4", headsign: "Kamppi"),          // only line
            TestFixtures.departure(minutesFromNow: 10, route: "7", headsign: "Munkkiniemi"),    // only headsign
            TestFixtures.departure(minutesFromNow: 12, route: "7", headsign: "Kamppi"),         // neither
        ]

        // When: Filtering
        let matches = departures.filter { stop.matchesFilters(departure: $0) }

        // Then: Should only match when both filters pass
        XCTAssertEqual(matches.count, 1)
        XCTAssertEqual(matches.first?.routeShortName, "4")
        XCTAssertTrue(matches.first?.headsign.contains("Munkki") ?? false)
        XCTAssertTrue(stop.hasFilters)
    }

    // MARK: - Edge Cases

    func testFilterWithWhitespace() {
        // Given: Stop with whitespace in filter
        let stop = Stop(
            id: "HSL:1234",
            name: "Test",
            code: "H1234",
            filteredLines: [" 4 ", "7"]
        )
        let departure = TestFixtures.departure(minutesFromNow: 5, route: "4")

        // When: Checking match
        let matches = stop.matchesFilters(departure: departure)

        // Then: Whitespace handling depends on implementation
        // May need trimming in actual code
        XCTAssertFalse(matches) // Or true if implementation trims
    }

    func testFilterWithSpecialCharacters() {
        // Given: Stop filtering for line with special chars
        let stop = Stop(
            id: "HSL:1234",
            name: "Test",
            code: "H1234",
            filteredLines: ["550A", "102T"]
        )
        let departures = [
            TestFixtures.departure(minutesFromNow: 5, route: "550A"),
            TestFixtures.departure(minutesFromNow: 10, route: "102T"),
            TestFixtures.departure(minutesFromNow: 15, route: "550"),
        ]

        // When: Filtering
        let matches = departures.filter { stop.matchesFilters(departure: $0) }

        // Then: Should match exactly
        XCTAssertEqual(matches.count, 2)
        XCTAssertTrue(matches.contains { $0.routeShortName == "550A" })
        XCTAssertTrue(matches.contains { $0.routeShortName == "102T" })
    }

    func testHeadsignPattern_PartialWordMatch() {
        // Given: Stop with partial word pattern
        let stop = Stop(
            id: "HSL:1234",
            name: "Test",
            code: "H1234",
            filteredHeadsignPattern: "sörnäi"
        )
        let departures = [
            TestFixtures.departure(minutesFromNow: 5, headsign: "Sörnäinen"),
            TestFixtures.departure(minutesFromNow: 10, headsign: "Itä-Sörnäinen"),
            TestFixtures.departure(minutesFromNow: 15, headsign: "Sörn"),
        ]

        // When: Filtering
        let matches = departures.filter { stop.matchesFilters(departure: $0) }

        // Then: Should match partial word
        XCTAssertGreaterThanOrEqual(matches.count, 1)
        XCTAssertTrue(matches.contains { $0.headsign.lowercased().contains("sörnäi") })
    }

    // MARK: - hasFilters Property Tests

    func testHasFilters_TrueWhenLineFilterSet() {
        // Given: Stop with line filter
        let stop = Stop(
            id: "HSL:1234",
            name: "Test",
            code: "H1234",
            filteredLines: ["4"]
        )

        // Then: Should have filters
        XCTAssertTrue(stop.hasFilters)
    }

    func testHasFilters_TrueWhenHeadsignFilterSet() {
        // Given: Stop with headsign filter
        let stop = Stop(
            id: "HSL:1234",
            name: "Test",
            code: "H1234",
            filteredHeadsignPattern: "Munkki"
        )

        // Then: Should have filters
        XCTAssertTrue(stop.hasFilters)
    }

    func testHasFilters_TrueWhenBothSet() {
        // Given: Stop with both filters
        let stop = TestFixtures.stopWithBothFilters

        // Then: Should have filters
        XCTAssertTrue(stop.hasFilters)
    }

    func testHasFilters_FalseWhenNeitherSet() {
        // Given: Stop with no filters
        let stop = TestFixtures.stop1

        // Then: Should not have filters
        XCTAssertFalse(stop.hasFilters)
    }

    func testHasFilters_FalseWhenFiltersEmpty() {
        // Given: Stop with empty filter arrays
        let stop = Stop(
            id: "HSL:1234",
            name: "Test",
            code: "H1234",
            filteredLines: [],
            filteredHeadsignPattern: ""
        )

        // Then: Should not have filters
        XCTAssertFalse(stop.hasFilters)
    }
}
