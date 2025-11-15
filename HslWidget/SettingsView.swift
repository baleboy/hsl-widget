//
//  SettingsView.swift
//  HslWidget
//
//  Settings view for configuring app behavior
//

import SwiftUI
import CoreLocation

struct SettingsView: View {
    @StateObject private var locationManager = LocationManager.shared
    @Environment(\.dismiss) private var dismiss
    @AppStorage("backgroundLocationEnabled", store: UserDefaults(suiteName: "group.balenet.widget"))
    private var backgroundLocationEnabled = false

    var body: some View {
        NavigationView {
            Form {
                Section {
                    Toggle(isOn: $backgroundLocationEnabled) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Background Location Updates")
                                .font(.headline)
                            Text("Automatically update widget when you move")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .onChange(of: backgroundLocationEnabled) { _, newValue in
                        handleBackgroundLocationToggle(enabled: newValue)
                    }
                } header: {
                    Text("Location")
                } footer: {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("When enabled, the widget will automatically update to show the nearest stop as you move around the city.")

                        Text("Battery Impact: Minimal")
                            .font(.caption)
                            .fontWeight(.semibold)

                        Text("This feature uses \"significant location changes\" which only triggers when you move approximately 500 meters. It does not continuously track your location.")
                            .font(.caption)
                    }
                }

                Section {
                    HStack {
                        Text("Permission Status")
                        Spacer()
                        Text(authorizationStatusText)
                            .foregroundColor(authorizationStatusColor)
                    }

                    if needsPermissionUpgrade {
                        Button(action: openAppSettings) {
                            HStack {
                                Image(systemName: "gear")
                                Text("Open Settings")
                                Spacer()
                                Image(systemName: "arrow.up.right.square")
                                    .font(.caption)
                            }
                        }
                    }
                } header: {
                    Text("Location Permissions")
                } footer: {
                    if needsPermissionUpgrade {
                        Text("To enable background location updates, you need to grant \"Always\" permission in Settings. Tap the button above to open Settings.")
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var authorizationStatusText: String {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            return "Not Requested"
        case .restricted:
            return "Restricted"
        case .denied:
            return "Denied"
        case .authorizedWhenInUse:
            return "While Using App"
        case .authorizedAlways:
            return "Always"
        @unknown default:
            return "Unknown"
        }
    }

    private var authorizationStatusColor: Color {
        switch locationManager.authorizationStatus {
        case .authorizedAlways:
            return .green
        case .authorizedWhenInUse:
            return .orange
        case .denied, .restricted:
            return .red
        case .notDetermined:
            return .secondary
        @unknown default:
            return .secondary
        }
    }

    private var needsPermissionUpgrade: Bool {
        backgroundLocationEnabled &&
        locationManager.authorizationStatus != .authorizedAlways
    }

    private func handleBackgroundLocationToggle(enabled: Bool) {
        if enabled {
            // Request "Always" permission
            locationManager.requestAlwaysAuthorization()
            locationManager.enableBackgroundLocationUpdates()
        } else {
            // Switch back to foreground-only
            locationManager.disableBackgroundLocationUpdates()
        }
    }

    private func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    SettingsView()
}
