//
//  WidgetSetupInstructionsView.swift
//  HslWidget
//
//  Reusable view showing instructions for adding the widget to lock screen
//  Used in both onboarding and settings
//

import SwiftUI

struct WidgetSetupInstructionsView: View {
    var body: some View {
        VStack(spacing: 24) {
            Text("Add the widget")
                .font(.roundedTitle2)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 16) {
                InstructionRow(number: 1, text: "Long-press your lock screen")
                InstructionRow(number: 2, text: "Tap \"Customize\"")
                InstructionRow(number: 3, text: "Tap the area above or below the time")
                InstructionRow(number: 4, text: "Find \"HSL Widget\" and add it")
            }
            .padding(.horizontal, 32)

            Text("You can also add a widget to your home screen.")
                .font(.roundedFootnote)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }
}

// MARK: - Instruction Row

private struct InstructionRow: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Text("\(number)")
                .font(.roundedHeadline)
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(Circle().fill(Color.accentColor))

            Text(text)
                .font(.roundedBody)
                .foregroundColor(.primary)

            Spacer()
        }
    }
}

#Preview {
    WidgetSetupInstructionsView()
}
