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
        VStack(spacing: 12) {
            // Time display
            Text("9:41")
                .font(.system(size: 64, weight: .light, design: .rounded))
                .foregroundColor(.primary)

            // Widget mockup
            WidgetMockup()
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(.systemGray6))
        )
    }
}

private struct WidgetMockup: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "tram.fill")
                    .font(.system(size: 12))
                Text("Lasipalatsi")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                Spacer()
            }
            .foregroundColor(.primary)

            HStack(spacing: 16) {
                DepartureMockupRow(line: "9", destination: "Pasila", time: "2 min")
                DepartureMockupRow(line: "3", destination: "Olympiaterminaali", time: "5 min")
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
        )
    }
}

private struct DepartureMockupRow: View {
    let line: String
    let destination: String
    let time: String

    var body: some View {
        HStack(spacing: 4) {
            Text(line)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.green)
            Text(destination)
                .font(.system(size: 11, design: .rounded))
                .foregroundColor(.secondary)
                .lineLimit(1)
            Spacer()
            Text(time)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.primary)
        }
    }
}

#Preview {
    WelcomePage(onContinue: {})
}
