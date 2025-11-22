//
//  MockHslApi.swift
//  HslWidgetTests
//
//  Mock API for testing without network calls
//

import Foundation
@testable import HslWidget

/// Mock implementation of HslApi for testing
class MockHslApi {

    // MARK: - Mock Data

    var mockStops: [Stop] = []
    var mockDepartures: [Departure] = []
    var mockHeadsigns: [String] = []

    // MARK: - Call Tracking

    var fetchAllStopsCalled = false
    var fetchDeparturesCalled = false
    var fetchHeadsignsCalled = false

    var lastFetchedStationId: String?
    var lastFetchedStopId: String?
    var lastNumberOfResults: Int?

    // MARK: - Error Simulation

    var shouldThrowError = false
    var errorToThrow: Error = NSError(domain: "TestError", code: -1)

    // MARK: - API Methods

    func fetchAllStops() async throws -> [Stop] {
        fetchAllStopsCalled = true

        if shouldThrowError {
            throw errorToThrow
        }

        return mockStops
    }

    func fetchDepartures(stationId: String, numberOfResults: Int) async throws -> [Departure] {
        fetchDeparturesCalled = true
        lastFetchedStationId = stationId
        lastNumberOfResults = numberOfResults

        if shouldThrowError {
            throw errorToThrow
        }

        return mockDepartures
    }

    func fetchHeadsigns(stopId: String) async throws -> [String] {
        fetchHeadsignsCalled = true
        lastFetchedStopId = stopId

        if shouldThrowError {
            throw errorToThrow
        }

        return mockHeadsigns
    }

    // MARK: - Helper Methods

    func reset() {
        mockStops = []
        mockDepartures = []
        mockHeadsigns = []

        fetchAllStopsCalled = false
        fetchDeparturesCalled = false
        fetchHeadsignsCalled = false

        lastFetchedStationId = nil
        lastFetchedStopId = nil
        lastNumberOfResults = nil

        shouldThrowError = false
    }
}
