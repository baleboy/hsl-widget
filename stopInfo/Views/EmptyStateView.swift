//
//  EmptyStateView.swift
//  stopInfo
//
//  Created by Claude Code
//

import SwiftUI

/// Empty state when no favorites are configured or no departures available
struct EmptyStateView: View {
    let entry: TimetableEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            if entry.state == .noFavorites {
                Text("No favorites")
                    .font(.headline)
                    .widgetAccentable()
                Text("Open the app to select favorite stops")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            } else {
                Text(entry.stopName)
                    .font(.headline)
                    .widgetAccentable()
                    .lineLimit(1)
                Text("No departures available")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}
