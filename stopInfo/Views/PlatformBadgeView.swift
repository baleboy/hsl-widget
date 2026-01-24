//
//  PlatformBadgeView.swift
//  stopInfo
//
//  Created by Claude Code
//

import SwiftUI

/// Platform badge that displays differently for trains (white on black rounded square)
struct PlatformBadgeView: View {
    let platformCode: String
    let mode: String?
    let font: Font

    private var isRail: Bool {
        mode?.uppercased() == "RAIL"
    }

    var body: some View {
        if isRail {
            Text("P\(platformCode)")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 3)
                        .fill(.black)
                )
        } else {
            Text("P\(platformCode)")
                .font(font)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
    }
}
