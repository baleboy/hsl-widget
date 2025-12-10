//
//  LocationPermissionPage.swift
//  HslWidget
//
//  Onboarding screen explaining and requesting location permission
//

import SwiftUI
import CoreLocation

struct LocationPermissionPage: View {
    @ObservedObject var locationManager: LocationManager
    let onContinue: () -> Void
    let onSkip: () -> Void

    @State private var hasRequestedPermission = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon
            Image(systemName: "location.fill")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)
                .padding(.bottom, 8)

            VStack(spacing: 12) {
                Text("Show your nearest stop")
                    .font(.roundedTitle2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)

                Text("Allow location access so the widget automatically shows departures from the stop closest to you.")
                    .font(.roundedBody)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            VStack(spacing: 12) {
                if hasGrantedPermission {
                    // Permission granted - show success and continue
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Location enabled")
                            .font(.roundedHeadline)
                            .foregroundColor(.green)
                    }
                    .padding(.bottom, 8)

                    Text("You can enable automatic updates when you move in Settings.")
                        .font(.roundedFootnote)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)

                    OnboardingButton(title: "Continue", action: onContinue)
                } else {
                    OnboardingButton(title: "Enable Location", action: requestLocation)
                }

                Button("Maybe later") {
                    onSkip()
                }
                .font(.roundedBody)
                .foregroundColor(.secondary)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 20)
        }
        .onChange(of: locationManager.authorizationStatus) { _, newStatus in
            if newStatus == .authorizedWhenInUse || newStatus == .authorizedAlways {
                // Auto-advance after a short delay when permission is granted
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    onContinue()
                }
            }
        }
    }

    private var hasGrantedPermission: Bool {
        locationManager.authorizationStatus == .authorizedWhenInUse ||
        locationManager.authorizationStatus == .authorizedAlways
    }

    private func requestLocation() {
        hasRequestedPermission = true
        locationManager.requestPermission()
    }
}

#Preview {
    LocationPermissionPage(
        locationManager: LocationManager.shared,
        onContinue: {},
        onSkip: {}
    )
}
