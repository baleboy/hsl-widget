//
//  MockUserDefaults.swift
//  HslWidgetTests
//
//  Mock UserDefaults for testing persistence without side effects
//

import Foundation

/// In-memory UserDefaults for isolated testing
class MockUserDefaults: UserDefaults {

    private var storage: [String: Any] = [:]

    override func set(_ value: Any?, forKey defaultName: String) {
        storage[defaultName] = value
    }

    override func data(forKey defaultName: String) -> Data? {
        storage[defaultName] as? Data
    }

    override func integer(forKey defaultName: String) -> Int {
        storage[defaultName] as? Int ?? 0
    }

    override func object(forKey defaultName: String) -> Any? {
        storage[defaultName]
    }

    override func removeObject(forKey defaultName: String) {
        storage.removeValue(forKey: defaultName)
    }

    func clear() {
        storage.removeAll()
    }
}
