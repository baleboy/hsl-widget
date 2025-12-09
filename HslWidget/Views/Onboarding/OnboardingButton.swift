//
//  OnboardingButton.swift
//  HslWidget
//
//  Reusable primary button style for onboarding screens
//

import SwiftUI

struct OnboardingButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.roundedHeadline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(12)
        }
    }
}

#Preview {
    OnboardingButton(title: "Continue", action: {})
        .padding()
}
