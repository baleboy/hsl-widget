//
//  SmokeTests.swift
//  HslWidgetTests
//
//  Basic smoke tests to catch configuration errors and crashes
//

import XCTest
@testable import HslWidget

final class SmokeTests: XCTestCase {

    // MARK: - Configuration Tests

    func testAPIKeyIsConfigured() {
        // This test ensures the API key is loaded from Info.plist
        // If this fails, you likely forgot to set HSL_API_KEY in Config.xcconfig
        XCTAssertNotNil(HslApi.apiKey, "API key should be configured in Info.plist")
        XCTAssertFalse(HslApi.apiKey!.isEmpty, "API key should not be empty")
        XCTAssertNotEqual(HslApi.apiKey, "YOUR_API_KEY_HERE", "API key should be replaced with actual key")
    }

    func testAppGroupIsConfigured() {
        // Verify the app group UserDefaults is accessible
        let sharedDefaults = UserDefaults(suiteName: "group.balenet.widget")
        XCTAssertNotNil(sharedDefaults, "App group UserDefaults should be accessible")
    }

    // MARK: - Model Tests

    func testStopCanBeCreated() {
        // Basic test that Stop model can be instantiated
        let stop = Stop(id: "HSL:1234", name: "Test Stop", code: "H1234")
        XCTAssertEqual(stop.id, "HSL:1234")
        XCTAssertEqual(stop.name, "Test Stop")
        XCTAssertEqual(stop.code, "H1234")
    }

    func testStopCodable() {
        // Verify Stop can be encoded/decoded (critical for favorites)
        let original = Stop(
            id: "HSL:1234",
            name: "Test Stop",
            code: "H1234",
            latitude: 60.159,
            longitude: 24.9208
        )

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        do {
            let data = try encoder.encode(original)
            let decoded = try decoder.decode(Stop.self, from: data)

            XCTAssertEqual(decoded.id, original.id)
            XCTAssertEqual(decoded.name, original.name)
            XCTAssertEqual(decoded.code, original.code)
            XCTAssertEqual(decoded.latitude, original.latitude)
            XCTAssertEqual(decoded.longitude, original.longitude)
        } catch {
            XCTFail("Stop encoding/decoding failed: \(error)")
        }
    }

    func testDepartureCanBeCreated() {
        // Basic test that Departure model can be instantiated
        let departure = Departure(
            departureTime: Date(),
            routeShortName: "4",
            headsign: "Munkkiniemi"
        )
        XCTAssertEqual(departure.routeShortName, "4")
        XCTAssertEqual(departure.headsign, "Munkkiniemi")
    }

    // MARK: - Manager Tests

    func testFavoritesManagerCanBeInstantiated() {
        // Verify FavoritesManager singleton works
        let manager = FavoritesManager.shared
        XCTAssertNotNil(manager)

        // Should return an array (empty or not) without crashing
        let favorites = manager.getFavorites()
        XCTAssertNotNil(favorites)
    }

    func testHslApiCanBeInstantiated() {
        // Verify HslApi singleton works
        let api = HslApi.shared
        XCTAssertNotNil(api)
    }

    // MARK: - Filter Logic Tests

    func testStopFilteringWithNoFilters() {
        // Verify default behavior (no filters = show all departures)
        let stop = Stop(id: "HSL:1234", name: "Test", code: "H1234")
        let departure = Departure(
            departureTime: Date(),
            routeShortName: "4",
            headsign: "Munkkiniemi"
        )

        XCTAssertTrue(stop.matchesFilters(departure: departure))
        XCTAssertFalse(stop.hasFilters)
    }

    func testStopFilteringWithLineFilter() {
        // Verify line filtering works
        let stop = Stop(
            id: "HSL:1234",
            name: "Test",
            code: "H1234",
            filteredLines: ["4", "5"]
        )

        let matchingDeparture = Departure(
            departureTime: Date(),
            routeShortName: "4",
            headsign: "Munkkiniemi"
        )
        let nonMatchingDeparture = Departure(
            departureTime: Date(),
            routeShortName: "7",
            headsign: "Kamppi"
        )

        XCTAssertTrue(stop.matchesFilters(departure: matchingDeparture))
        XCTAssertFalse(stop.matchesFilters(departure: nonMatchingDeparture))
        XCTAssertTrue(stop.hasFilters)
    }

    func testStopFilteringWithHeadsignPattern() {
        // Verify headsign pattern filtering works
        let stop = Stop(
            id: "HSL:1234",
            name: "Test",
            code: "H1234",
            filteredHeadsignPattern: "Munkki"
        )

        let matchingDeparture = Departure(
            departureTime: Date(),
            routeShortName: "4",
            headsign: "Munkkiniemi"
        )
        let nonMatchingDeparture = Departure(
            departureTime: Date(),
            routeShortName: "4",
            headsign: "Kamppi"
        )

        XCTAssertTrue(stop.matchesFilters(departure: matchingDeparture))
        XCTAssertFalse(stop.matchesFilters(departure: nonMatchingDeparture))
        XCTAssertTrue(stop.hasFilters)
    }
}
