//
//  FavoritesManagerTests.swift
//  HslWidgetTests
//
//  Unit tests for FavoritesManager
//

import XCTest
@testable import HslWidget

final class FavoritesManagerTests: XCTestCase {

    // Note: These tests use the real FavoritesManager which uses shared UserDefaults
    // In a production setup, we'd inject MockUserDefaults via dependency injection

    override func setUp() {
        super.setUp()
        // Clear any existing favorites before each test
        clearFavorites()
    }

    override func tearDown() {
        // Clean up after tests
        clearFavorites()
        super.tearDown()
    }

    // MARK: - Basic CRUD Tests

    func testAddFavorite_StoresStop() {
        // Given: A stop to add
        let stop = TestFixtures.stop1
        let manager = FavoritesManager.shared

        // When: Adding as favorite
        manager.addFavorite(stop)

        // Then: Should be in favorites
        let favorites = manager.getFavorites()
        XCTAssertEqual(favorites.count, 1)
        XCTAssertEqual(favorites.first?.id, stop.id)
        XCTAssertEqual(favorites.first?.name, stop.name)
    }

    func testAddFavorite_PreventsDuplicates() {
        // Given: Manager with one favorite
        let stop = TestFixtures.stop1
        let manager = FavoritesManager.shared
        manager.addFavorite(stop)

        // When: Adding same stop again
        manager.addFavorite(stop)

        // Then: Should still have only one
        let favorites = manager.getFavorites()
        XCTAssertEqual(favorites.count, 1)
    }

    func testRemoveFavorite_RemovesStop() {
        // Given: Manager with two favorites
        let stop1 = TestFixtures.stop1
        let stop2 = TestFixtures.stop2
        let manager = FavoritesManager.shared
        manager.addFavorite(stop1)
        manager.addFavorite(stop2)

        // When: Removing one
        manager.removeFavorite(stop1)

        // Then: Should only have the other
        let favorites = manager.getFavorites()
        XCTAssertEqual(favorites.count, 1)
        XCTAssertEqual(favorites.first?.id, stop2.id)
    }

    func testGetFavorites_EmptyWhenNone() {
        // Given: Fresh manager
        let manager = FavoritesManager.shared

        // When: Getting favorites
        let favorites = manager.getFavorites()

        // Then: Should be empty
        XCTAssertEqual(favorites.count, 0)
    }

    func testGetFavorites_ReturnsMultiple() {
        // Given: Multiple favorites added
        let stops = [TestFixtures.stop1, TestFixtures.stop2, TestFixtures.stop3]
        let manager = FavoritesManager.shared
        stops.forEach { manager.addFavorite($0) }

        // When: Getting favorites
        let favorites = manager.getFavorites()

        // Then: Should return all
        XCTAssertEqual(favorites.count, 3)
    }

    // MARK: - Toggle Tests

    func testToggleFavorite_AddsWhenNotPresent() {
        // Given: Stop not in favorites
        let stop = TestFixtures.stop1
        let manager = FavoritesManager.shared

        // When: Toggling
        manager.toggleFavorite(stop)

        // Then: Should be added
        XCTAssertTrue(manager.isFavorite(stop))
        XCTAssertEqual(manager.getFavorites().count, 1)
    }

    func testToggleFavorite_RemovesWhenPresent() {
        // Given: Stop already in favorites
        let stop = TestFixtures.stop1
        let manager = FavoritesManager.shared
        manager.addFavorite(stop)

        // When: Toggling
        manager.toggleFavorite(stop)

        // Then: Should be removed
        XCTAssertFalse(manager.isFavorite(stop))
        XCTAssertEqual(manager.getFavorites().count, 0)
    }

    // MARK: - Query Tests

    func testIsFavorite_ReturnsTrueWhenPresent() {
        // Given: Stop in favorites
        let stop = TestFixtures.stop1
        let manager = FavoritesManager.shared
        manager.addFavorite(stop)

        // When: Checking if favorite
        let result = manager.isFavorite(stop)

        // Then: Should return true
        XCTAssertTrue(result)
    }

    func testIsFavorite_ReturnsFalseWhenNotPresent() {
        // Given: Stop not in favorites
        let stop = TestFixtures.stop1
        let manager = FavoritesManager.shared

        // When: Checking if favorite
        let result = manager.isFavorite(stop)

        // Then: Should return false
        XCTAssertFalse(result)
    }

    // MARK: - Update Tests

    func testUpdateFavorite_ModifiesExistingStop() {
        // Given: Favorite stop without filters
        let originalStop = TestFixtures.stop1
        let manager = FavoritesManager.shared
        manager.addFavorite(originalStop)

        // When: Updating with filters
        let updatedStop = Stop(
            id: originalStop.id,
            name: originalStop.name,
            code: originalStop.code,
            latitude: originalStop.latitude,
            longitude: originalStop.longitude,
            filteredLines: ["4", "7"]
        )
        manager.updateFavorite(updatedStop)

        // Then: Should be updated
        let favorites = manager.getFavorites()
        XCTAssertEqual(favorites.count, 1)
        XCTAssertEqual(favorites.first?.filteredLines?.count, 2)
        XCTAssertTrue(favorites.first?.hasFilters ?? false)
    }

    func testUpdateFavorite_OnlyUpdatesMatchingId() {
        // Given: Two favorites
        let stop1 = TestFixtures.stop1
        let stop2 = TestFixtures.stop2
        let manager = FavoritesManager.shared
        manager.addFavorite(stop1)
        manager.addFavorite(stop2)

        // When: Updating one
        let updatedStop = Stop(
            id: stop1.id,
            name: "Updated Name",
            code: stop1.code
        )
        manager.updateFavorite(updatedStop)

        // Then: Only first should be updated
        let favorites = manager.getFavorites()
        XCTAssertEqual(favorites.count, 2)

        let updatedInList = favorites.first { $0.id == stop1.id }
        XCTAssertEqual(updatedInList?.name, "Updated Name")

        let unchanged = favorites.first { $0.id == stop2.id }
        XCTAssertEqual(unchanged?.name, stop2.name)
    }

    // MARK: - Persistence Tests

    func testFavorites_PersistAcrossInstances() {
        // Given: Favorites added via one manager instance
        let stop = TestFixtures.stop1
        let manager1 = FavoritesManager.shared
        manager1.addFavorite(stop)

        // When: Getting favorites from same singleton
        let manager2 = FavoritesManager.shared
        let favorites = manager2.getFavorites()

        // Then: Should persist (both are same instance)
        XCTAssertEqual(favorites.count, 1)
        XCTAssertEqual(favorites.first?.id, stop.id)
    }

    func testFavorites_EncodesAndDecodesCorrectly() {
        // Given: Stop with all properties
        let stop = Stop(
            id: "HSL:1234",
            name: "Test Stop",
            code: "H1234",
            latitude: 60.159,
            longitude: 24.9208,
            vehicleModes: ["TRAM", "BUS"],
            filteredLines: ["4", "7"],
            filteredHeadsignPattern: "Munkki"
        )
        let manager = FavoritesManager.shared

        // When: Adding and retrieving
        manager.addFavorite(stop)
        let favorites = manager.getFavorites()

        // Then: All properties should be preserved
        XCTAssertEqual(favorites.count, 1)
        let retrieved = favorites.first!
        XCTAssertEqual(retrieved.id, stop.id)
        XCTAssertEqual(retrieved.name, stop.name)
        XCTAssertEqual(retrieved.code, stop.code)
        XCTAssertEqual(retrieved.latitude, stop.latitude)
        XCTAssertEqual(retrieved.longitude, stop.longitude)
        XCTAssertEqual(retrieved.vehicleModes, stop.vehicleModes)
        XCTAssertEqual(retrieved.filteredLines, stop.filteredLines)
        XCTAssertEqual(retrieved.filteredHeadsignPattern, stop.filteredHeadsignPattern)
    }

    // MARK: - Helper Methods

    private func clearFavorites() {
        let sharedDefaults = UserDefaults(suiteName: "group.balenet.widget")
        sharedDefaults?.removeObject(forKey: "favoriteStops")
    }
}
