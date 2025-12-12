//
//  LocationManager.swift
//  HslWidget
//
//  Manages user location and shares it with the widget extension
//

import Foundation
import CoreLocation
import WidgetKit

class LocationManager: NSObject, ObservableObject {
    static let shared = LocationManager()

    private let locationManager = CLLocationManager()
    private let sharedDefaults = UserDefaults(suiteName: "group.balenet.widget")

    private let latitudeKey = "currentLatitude"
    private let longitudeKey = "currentLongitude"

    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var currentLocation: CLLocation?

    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.distanceFilter = 100 // Update every 100 meters

        authorizationStatus = locationManager.authorizationStatus
    }

    /// Request location permissions (When In Use)
    func requestPermission() {
        print("LocationManager: Requesting when-in-use authorization")
        locationManager.requestWhenInUseAuthorization()
    }

    /// Request always authorization for background location
    func requestAlwaysAuthorization() {
        print("LocationManager: Requesting always authorization")
        locationManager.requestAlwaysAuthorization()
    }

    /// Start monitoring location (foreground)
    func startMonitoring() {
        print("LocationManager: Starting location updates")
        locationManager.startUpdatingLocation()
    }

    /// Stop monitoring location
    func stopMonitoring() {
        print("LocationManager: Stopping location updates")
        locationManager.stopUpdatingLocation()
    }

    /// Enable background location updates (significant location changes)
    func enableBackgroundLocationUpdates() {
        guard authorizationStatus == .authorizedAlways else {
            print("LocationManager: Cannot enable background updates without 'Always' authorization")
            return
        }
        print("LocationManager: Enabling significant location change monitoring")
        locationManager.startMonitoringSignificantLocationChanges()
        // Also keep foreground updates for when app is open
        locationManager.startUpdatingLocation()
    }

    /// Disable background location updates
    func disableBackgroundLocationUpdates() {
        print("LocationManager: Disabling significant location change monitoring")
        locationManager.stopMonitoringSignificantLocationChanges()
        // Keep foreground updates if we have any location permission
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            locationManager.startUpdatingLocation()
        }
    }

    /// Request a single immediate location update
    func requestImmediateLocation() {
        print("LocationManager: Requesting immediate location update")
        locationManager.requestLocation()
    }

    /// Get the last known location from shared storage
    func getSharedLocation() -> CLLocation? {
        guard let latitude = sharedDefaults?.double(forKey: latitudeKey),
              let longitude = sharedDefaults?.double(forKey: longitudeKey),
              latitude != 0 && longitude != 0 else {
            return nil
        }
        return CLLocation(latitude: latitude, longitude: longitude)
    }

    /// Save location to shared storage
    private func saveLocation(_ location: CLLocation) {
        sharedDefaults?.set(location.coordinate.latitude, forKey: latitudeKey)
        sharedDefaults?.set(location.coordinate.longitude, forKey: longitudeKey)

        // Reload widget when location changes significantly
        WidgetCenter.shared.reloadAllTimelines()
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        print("LocationManager: Authorization status changed to: \(authorizationStatus.rawValue)")

        let backgroundLocationEnabled = sharedDefaults?.bool(forKey: "backgroundLocationEnabled") ?? false

        switch authorizationStatus {
        case .authorizedAlways:
            print("LocationManager: Always authorization granted")
            if backgroundLocationEnabled {
                enableBackgroundLocationUpdates()
            } else {
                startMonitoring()
            }
        case .authorizedWhenInUse:
            print("LocationManager: When-in-use authorization granted")
            // Disable background if it was enabled (user downgraded permission)
            if backgroundLocationEnabled {
                sharedDefaults?.set(false, forKey: "backgroundLocationEnabled")
                disableBackgroundLocationUpdates()
            } else {
                startMonitoring()
            }
        case .denied, .restricted:
            print("LocationManager: Location denied/restricted, stopping monitoring")
            stopMonitoring()
            disableBackgroundLocationUpdates()
        case .notDetermined:
            print("LocationManager: Location permission not determined yet")
            break
        @unknown default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        print("LocationManager: Location updated: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        currentLocation = location
        saveLocation(location)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("LocationManager: Error: \(error.localizedDescription)")
    }
}
