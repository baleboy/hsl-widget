//
//  OnboardingContainerView.swift
//  HslWidget
//
//  Container view managing the onboarding flow with progress indicator
//

import SwiftUI

struct OnboardingContainerView: View {
    let onComplete: () -> Void

    @State private var currentPage = 0
    @State private var showStopPicker = false
    @State private var hasAddedStop = false
    @StateObject private var locationManager = LocationManager.shared

    private let totalPages = 4

    var body: some View {
        VStack(spacing: 0) {
            // Skip button
            HStack {
                Spacer()
                Button("Skip") {
                    onComplete()
                }
                .font(.roundedBody)
                .foregroundColor(.secondary)
                .padding()
            }

            Spacer()

            // Page content
            TabView(selection: $currentPage) {
                WelcomePage(onContinue: { advanceToPage(1) })
                    .tag(0)

                LocationPermissionPage(
                    locationManager: locationManager,
                    onContinue: { advanceToPage(2) },
                    onSkip: { advanceToPage(2) }
                )
                .tag(1)

                AddStopPage(
                    onFindStops: { showStopPicker = true },
                    onSkip: { advanceToPage(3) }
                )
                .tag(2)

                WidgetSetupPage(onDone: onComplete)
                    .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentPage)

            Spacer()

            // Progress dots
            ProgressDotsView(currentPage: currentPage, totalPages: totalPages)
                .padding(.bottom, 40)
        }
        .sheet(isPresented: $showStopPicker) {
            StopPickerView(onDismiss: {
                showStopPicker = false
                // Check if user added at least one stop
                if !FavoritesManager.shared.getFavorites().isEmpty {
                    hasAddedStop = true
                    advanceToPage(3)
                }
            })
        }
    }

    private func advanceToPage(_ page: Int) {
        withAnimation {
            currentPage = page
        }
    }
}

// MARK: - Progress Dots

struct ProgressDotsView: View {
    let currentPage: Int
    let totalPages: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalPages, id: \.self) { index in
                Circle()
                    .fill(index == currentPage ? Color.accentColor : Color.secondary.opacity(0.3))
                    .frame(width: 8, height: 8)
                    .animation(.easeInOut(duration: 0.2), value: currentPage)
            }
        }
    }
}

#Preview {
    OnboardingContainerView(onComplete: {})
}
