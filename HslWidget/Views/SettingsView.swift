//
//  SettingsView.swift
//  HslWidget
//
//  Settings view for configuring app behavior
//

import SwiftUI
import CoreLocation
import WidgetKit

struct SettingsView: View {
    @StateObject private var locationManager = LocationManager.shared
    @Environment(\.dismiss) private var dismiss
    @AppStorage("backgroundLocationEnabled", store: UserDefaults(suiteName: "group.balenet.widget"))
    private var backgroundLocationEnabled = false
    @AppStorage("numberOfDepartures", store: UserDefaults(suiteName: "group.balenet.widget"))
    private var numberOfDepartures = 2
    @State private var showingDeleteConfirmation = false
    @State private var showingWidgetSetup = false

    var body: some View {
        NavigationView {
            Form {
                Section {
                    Picker(selection: $numberOfDepartures) {
                        ForEach(2...3, id: \.self) { count in
                            Text("\(count)").tag(count)
                        }
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Number of departures")
                                .font(.roundedHeadline)
                            Text("How many departures to show in the lock screen")
                                .font(.roundedCaption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .onChange(of: numberOfDepartures) { _, _ in
                        WidgetCenter.shared.reloadAllTimelines()
                    }
                } header: {
                    Text("Widget Display")
                }

                Section {
                    Button(action: { showingWidgetSetup = true }) {
                        HStack {
                            Image(systemName: "apps.iphone")
                            Text("How to Add Widget")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.roundedCaption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Help")
                }

                Section {
                    Toggle(isOn: $backgroundLocationEnabled) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Background Location Updates")
                                .font(.roundedHeadline)
                            Text("Automatically update widget when you move")
                                .font(.roundedCaption)
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
                            .font(.roundedCaption)
                            .fontWeight(.semibold)

                        Text("This feature uses \"significant location changes\" which only triggers when you move approximately 500 meters. It does not continuously track your location.")
                            .font(.roundedCaption)
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
                                    .font(.roundedCaption)
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

                Section {
                    Button(role: .destructive, action: {
                        showingDeleteConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Remove All Favorites")
                        }
                    }
                } header: {
                    Text("Favorites")
                } footer: {
                    Text("This will remove all favorite stops from your list.")
                }

                #if DEBUG
                Section {
                    Button(role: .destructive, action: clearAllUserDefaults) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Reset All Data")
                        }
                    }
                } header: {
                    Text("Debug")
                } footer: {
                    Text("Clears all UserDefaults including onboarding state. App will restart in onboarding mode.")
                }
                #endif
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
            .alert("Remove All Favorites?", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Remove All", role: .destructive) {
                    removeAllFavorites()
                }
            } message: {
                Text("This will permanently remove all your favorite stops. This action cannot be undone.")
            }
            .sheet(isPresented: $showingWidgetSetup) {
                WidgetSetupSheet()
            }
        }
    }

    private var authorizationStatusText: String {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            return String(localized: "Not Requested")
        case .restricted:
            return String(localized: "Restricted")
        case .denied:
            return String(localized: "Denied")
        case .authorizedWhenInUse:
            return String(localized: "While Using App")
        case .authorizedAlways:
            return String(localized: "Always")
        @unknown default:
            return String(localized: "Unknown")
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
            // Request "Always" permission - enableBackgroundLocationUpdates will be called
            // automatically in the delegate once permission is granted
            locationManager.requestAlwaysAuthorization()
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

    private func removeAllFavorites() {
        FavoritesManager.shared.removeAllFavorites()
    }

    #if DEBUG
    private func clearAllUserDefaults() {
        let suiteName = "group.balenet.widget"
        if let defaults = UserDefaults(suiteName: suiteName) {
            defaults.removePersistentDomain(forName: suiteName)
            defaults.synchronize()
        }
        WidgetCenter.shared.reloadAllTimelines()
        exit(0)
    }
    #endif
}

// MARK: - Widget Setup Sheet

private struct WidgetSetupSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                WidgetSetupInstructionsView()
                Spacer()
            }
            .navigationTitle("Add Widget")
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
}

#Preview {
    SettingsView()
}
