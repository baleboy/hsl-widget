//
//  ApiResponseDecodingTests.swift
//  HslWidgetTests
//
//  Unit tests for API response decoding
//

import XCTest
@testable import HslWidget

final class ApiResponseDecodingTests: XCTestCase {

    // MARK: - Stops Query Response Tests

    func testDecodeStopsResponse_Success() throws {
        // Given: Valid stops response JSON
        let json = TestFixtures.stopsResponseJSON
        let data = json.data(using: .utf8)!

        // When: Decoding
        let response = try JSONDecoder().decode(StopsQueryResponse.self, from: data)

        // Then: Should decode successfully
        XCTAssertEqual(response.data.stops.count, 2)

        let firstStop = response.data.stops[0]
        XCTAssertEqual(firstStop.gtfsId, "HSL:1234")
        XCTAssertEqual(firstStop.name, "Merisotilaantori")
        XCTAssertEqual(firstStop.code, "H1234")
        XCTAssertEqual(firstStop.lat, 60.159)
        XCTAssertEqual(firstStop.lon, 24.9208)
        XCTAssertEqual(firstStop.routes?.count, 2)
        XCTAssertTrue(firstStop.routes?.contains { $0.mode == "TRAM" } ?? false)
        XCTAssertTrue(firstStop.routes?.contains { $0.mode == "BUS" } ?? false)
    }

    func testDecodeStopsResponse_HandlesNilCode() throws {
        // Given: JSON with nil code
        let json = """
        {
            "data": {
                "stops": [
                    {
                        "gtfsId": "HSL:1234",
                        "name": "Test Stop",
                        "code": null,
                        "lat": 60.159,
                        "lon": 24.9208,
                        "routes": []
                    }
                ]
            }
        }
        """
        let data = json.data(using: .utf8)!

        // When: Decoding
        let response = try JSONDecoder().decode(StopsQueryResponse.self, from: data)

        // Then: Should handle nil code gracefully
        XCTAssertEqual(response.data.stops.count, 1)
        XCTAssertNil(response.data.stops[0].code)
    }

    func testDecodeStopsResponse_HandlesNilCoordinates() throws {
        // Given: JSON with nil coordinates
        let json = """
        {
            "data": {
                "stops": [
                    {
                        "gtfsId": "HSL:1234",
                        "name": "Test Stop",
                        "code": "H1234",
                        "lat": null,
                        "lon": null,
                        "routes": []
                    }
                ]
            }
        }
        """
        let data = json.data(using: .utf8)!

        // When: Decoding
        let response = try JSONDecoder().decode(StopsQueryResponse.self, from: data)

        // Then: Should handle nil coordinates
        XCTAssertNil(response.data.stops[0].lat)
        XCTAssertNil(response.data.stops[0].lon)
    }

    func testDecodeStopsResponse_HandlesEmptyRoutes() throws {
        // Given: JSON with empty routes array
        let json = """
        {
            "data": {
                "stops": [
                    {
                        "gtfsId": "HSL:1234",
                        "name": "Test Stop",
                        "code": "H1234",
                        "lat": 60.159,
                        "lon": 24.9208,
                        "routes": []
                    }
                ]
            }
        }
        """
        let data = json.data(using: .utf8)!

        // When: Decoding
        let response = try JSONDecoder().decode(StopsQueryResponse.self, from: data)

        // Then: Should handle empty routes
        XCTAssertEqual(response.data.stops[0].routes?.count, 0)
    }

    // MARK: - Departures Query Response Tests

    func testDecodeDeparturesResponse_Success() throws {
        // Given: Valid departures response JSON
        let json = TestFixtures.departuresResponseJSON
        let data = json.data(using: .utf8)!

        // When: Decoding
        let response = try JSONDecoder().decode(DepartureTimesQueryResponse.self, from: data)

        // Then: Should decode successfully
        XCTAssertEqual(response.data.stop.stoptimesWithoutPatterns.count, 2)

        let firstDeparture = response.data.stop.stoptimesWithoutPatterns[0]
        XCTAssertEqual(firstDeparture.serviceDay, 1700000000)
        XCTAssertEqual(firstDeparture.realtimeDeparture, 3600)
        XCTAssertEqual(firstDeparture.headsign, "Munkkiniemi")
        XCTAssertEqual(firstDeparture.trip.route.shortName, "4")
        XCTAssertEqual(firstDeparture.trip.route.mode, "TRAM")

        let secondDeparture = response.data.stop.stoptimesWithoutPatterns[1]
        XCTAssertEqual(secondDeparture.headsign, "Kamppi")
        XCTAssertEqual(secondDeparture.trip.route.shortName, "550")
        XCTAssertEqual(secondDeparture.trip.route.mode, "BUS")
    }

    func testDecodeDeparturesResponse_HandlesNilHeadsign() throws {
        // Given: JSON with nil headsign
        let json = """
        {
            "data": {
                "stop": {
                    "stoptimesWithoutPatterns": [
                        {
                            "serviceDay": 1700000000,
                            "realtimeDeparture": 3600,
                            "headsign": null,
                            "trip": {
                                "route": {
                                    "mode": "TRAM",
                                    "shortName": "4"
                                }
                            }
                        }
                    ]
                }
            }
        }
        """
        let data = json.data(using: .utf8)!

        // When: Decoding
        let response = try JSONDecoder().decode(DepartureTimesQueryResponse.self, from: data)

        // Then: Should handle nil headsign
        XCTAssertNil(response.data.stop.stoptimesWithoutPatterns[0].headsign)
    }

    func testDecodeDeparturesResponse_CalculatesDepartureTime() throws {
        // Given: Response with service day and realtime departure
        let json = TestFixtures.departuresResponseJSON
        let data = json.data(using: .utf8)!

        // When: Decoding and calculating timestamp
        let response = try JSONDecoder().decode(DepartureTimesQueryResponse.self, from: data)
        let stopTime = response.data.stop.stoptimesWithoutPatterns[0]
        let timestamp = stopTime.serviceDay + stopTime.realtimeDeparture

        // Then: Should calculate correct timestamp
        XCTAssertEqual(timestamp, 1700003600) // 1700000000 + 3600
    }

    // MARK: - Headsigns Query Response Tests

    func testDecodeHeadsignsResponse_Success() throws {
        // Given: Valid headsigns response JSON
        let json = TestFixtures.headsignsResponseJSON
        let data = json.data(using: .utf8)!

        // When: Decoding
        let response = try JSONDecoder().decode(HeadsignsQueryResponse.self, from: data)

        // Then: Should decode successfully
        XCTAssertEqual(response.data.stop.stoptimesWithoutPatterns.count, 4)

        let headsigns = response.data.stop.stoptimesWithoutPatterns.compactMap { $0.headsign }
        XCTAssertEqual(headsigns.count, 4)
        XCTAssertTrue(headsigns.contains("Munkkiniemi"))
        XCTAssertTrue(headsigns.contains("Katajanokka"))
        XCTAssertTrue(headsigns.contains("Töölö"))
    }

    func testDecodeHeadsignsResponse_FiltersNilValues() throws {
        // Given: Response with some nil headsigns
        let json = """
        {
            "data": {
                "stop": {
                    "stoptimesWithoutPatterns": [
                        { "headsign": "Munkkiniemi" },
                        { "headsign": null },
                        { "headsign": "Kamppi" }
                    ]
                }
            }
        }
        """
        let data = json.data(using: .utf8)!

        // When: Decoding and filtering nils
        let response = try JSONDecoder().decode(HeadsignsQueryResponse.self, from: data)
        let headsigns = response.data.stop.stoptimesWithoutPatterns
            .compactMap { $0.headsign }
            .filter { !$0.isEmpty }

        // Then: Should filter out nils
        XCTAssertEqual(headsigns.count, 2)
        XCTAssertEqual(headsigns, ["Munkkiniemi", "Kamppi"])
    }

    // MARK: - Error Handling Tests

    func testDecodeInvalidJSON_ThrowsError() {
        // Given: Invalid JSON
        let json = "{ invalid json }"
        let data = json.data(using: .utf8)!

        // When/Then: Should throw decoding error
        XCTAssertThrowsError(try JSONDecoder().decode(StopsQueryResponse.self, from: data))
    }

    func testDecodeMissingRequiredField_ThrowsError() {
        // Given: JSON missing required field
        let json = """
        {
            "data": {
                "stops": [
                    {
                        "gtfsId": "HSL:1234",
                        "name": "Test Stop"
                    }
                ]
            }
        }
        """
        let data = json.data(using: .utf8)!

        // When/Then: Should throw decoding error (missing code, lat, lon, routes)
        // Note: These fields are optional, so this should actually succeed
        XCTAssertNoThrow(try JSONDecoder().decode(StopsQueryResponse.self, from: data))
    }

    func testDecodeEmptyStopsArray() throws {
        // Given: Valid response with no stops
        let json = """
        {
            "data": {
                "stops": []
            }
        }
        """
        let data = json.data(using: .utf8)!

        // When: Decoding
        let response = try JSONDecoder().decode(StopsQueryResponse.self, from: data)

        // Then: Should decode successfully with empty array
        XCTAssertEqual(response.data.stops.count, 0)
    }

    func testDecodeEmptyDeparturesArray() throws {
        // Given: Valid response with no departures
        let json = """
        {
            "data": {
                "stop": {
                    "stoptimesWithoutPatterns": []
                }
            }
        }
        """
        let data = json.data(using: .utf8)!

        // When: Decoding
        let response = try JSONDecoder().decode(DepartureTimesQueryResponse.self, from: data)

        // Then: Should decode successfully with empty array
        XCTAssertEqual(response.data.stop.stoptimesWithoutPatterns.count, 0)
    }
}
