//
//  SharedLocationReader.swift
//  HslWidget
//
//  Lightweight location reader for widget extension
//  Reads cached location from shared UserDefaults without initializing CLLocationManager
//

import Foundation
import CoreLocation

/// Lightweight utility to read cached location from shared storage
/// Used by widget extension to avoid heavy CLLocationManager initialization
struct SharedLocationReader {

    private let sharedDefaults = UserDefaults(suiteName: "group.balenet.widget")
    private let latitudeKey = "currentLatitude"
    private let longitudeKey = "currentLongitude"

    /// Get the last known location from shared storage
    /// Returns nil if no location has been saved yet
    func getSharedLocation() -> CLLocation? {
        guard let latitude = sharedDefaults?.double(forKey: latitudeKey),
              let longitude = sharedDefaults?.double(forKey: longitudeKey),
              latitude != 0 && longitude != 0 else {
            return nil
        }
        return CLLocation(latitude: latitude, longitude: longitude)
    }
}
