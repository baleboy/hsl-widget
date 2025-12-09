//
//  WidgetSetupPage.swift
//  HslWidget
//
//  Final onboarding screen with widget setup instructions
//

import SwiftUI

struct WidgetSetupPage: View {
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            WidgetSetupInstructionsView()

            Spacer()

            OnboardingButton(title: "Done", action: onDone)
                .padding(.horizontal, 40)
                .padding(.bottom, 20)
        }
    }
}

#Preview {
    WidgetSetupPage(onDone: {})
}
