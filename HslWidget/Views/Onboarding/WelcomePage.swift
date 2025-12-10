//
//  WelcomePage.swift
//  HslWidget
//
//  First onboarding screen - value proposition
//

import SwiftUI

struct WelcomePage: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Lock screen mockup
            LockScreenMockup()
                .padding(.horizontal, 40)

            VStack(spacing: 12) {
                Text("Your departures at a glance")
                    .font(.roundedTitle2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)

                Text("See real-time bus and tram times right on your lock screen. No app needed.")
                    .font(.roundedBody)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            OnboardingButton(title: "Continue", action: onContinue)
                .padding(.horizontal, 40)
                .padding(.bottom, 20)
        }
    }
}

// MARK: - Lock Screen Mockup

private struct LockScreenMockup: View {
    var body: some View {
        Image("mockup")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}

#Preview {
    WelcomePage(onContinue: {})
}
