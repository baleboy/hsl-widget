//
//  FilterTooltipView.swift
//  HslWidget
//
//  Tooltip overlay shown after onboarding to introduce the filter feature
//

import SwiftUI

struct FilterTooltipView: View {
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }

            // Tooltip card
            VStack(spacing: 16) {
                Image(systemName: "hand.tap.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.accentColor)

                Text("Filter by line or direction")
                    .font(.roundedHeadline)
                    .multilineTextAlignment(.center)

                Text("Tap any stop to show only specific lines or destinations on your widget.")
                    .font(.roundedBody)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                Button(action: onDismiss) {
                    Text("Got it")
                        .font(.roundedHeadline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(Color.accentColor)
                        .cornerRadius(10)
                }
                .padding(.top, 8)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
            )
            .shadow(radius: 20)
            .padding(.horizontal, 40)
        }
        .transition(.opacity)
    }
}

#Preview {
    FilterTooltipView(onDismiss: {})
}
