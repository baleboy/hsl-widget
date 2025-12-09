//
//  AddStopPage.swift
//  HslWidget
//
//  Onboarding screen prompting user to add their first stop
//

import SwiftUI

struct AddStopPage: View {
    let onFindStops: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon
            Image(systemName: "star.fill")
                .font(.system(size: 60))
                .foregroundColor(.yellow)
                .padding(.bottom, 8)

            VStack(spacing: 12) {
                Text("Add your favorite stops")
                    .font(.roundedTitle2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)

                Text("Save the stops you use most. The widget will show whichever one is closest to you.")
                    .font(.roundedBody)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            VStack(spacing: 12) {
                OnboardingButton(title: "Find Stops", action: onFindStops)

                Button("I'll do this later") {
                    onSkip()
                }
                .font(.roundedBody)
                .foregroundColor(.secondary)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 20)
        }
    }
}

#Preview {
    AddStopPage(onFindStops: {}, onSkip: {})
}
