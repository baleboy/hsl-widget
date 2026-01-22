//
//  DelayBadgeView.swift
//  stopInfo
//
//  Created by Claude Code
//

import SwiftUI

/// Small capsule badge showing delay in minutes with inverted colors
struct DelayBadgeView: View {
    @Environment(\.widgetFamily) var family
    let delayMinutes: Int
    let font: Font

    private var isLockScreen: Bool {
        family == .accessoryRectangular || family == .accessoryInline || family == .accessoryCircular
    }

    var body: some View {
        if isLockScreen {
            Text("+\(delayMinutes)")
                .font(font)
                .foregroundColor(.black)
                .padding(.horizontal, 3)
                .padding(.vertical, 1)
                .background(Capsule().fill(.white))
        } else {
            Text("+\(delayMinutes)")
                .font(font)
                .foregroundColor(.white)
                .padding(.horizontal, 3)
                .padding(.vertical, 1)
                .background(Capsule().fill(.red))
        }
    }
}
