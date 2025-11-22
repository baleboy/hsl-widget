//
//  SystemSmallWidgetView.swift
//  stopInfo
//
//  Created by Claude Code
//

import SwiftUI

/// Home screen small widget layout with more space
struct SystemSmallWidgetView: View {
    let entry: TimetableEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            if entry.departures.isEmpty {
                EmptyStateView(entry: entry)
            } else {
                // Stop name
                Text(entry.stopName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .widgetAccentable()
                    .lineLimit(1)

                Divider()

                // Show up to 3 departures with destination
                ForEach(entry.departures.prefix(3)) { departure in
                    VStack(alignment: .leading, spacing: 1) {
                        HStack(spacing: 4) {
                            // Route with icon
                            Label {
                                Text(departure.routeShortName)
                            } icon: {
                                Image(systemName: transitModeIconName(for: departure.mode))
                                    .foregroundColor(transitModeColor(for: departure.mode))
                            }
                            .font(.caption)
                            .fontWeight(.medium)

                            Spacer()

                            // Time
                            Text(WidgetViewFormatters.timeFormatter.string(from: departure.departureTime))
                                .font(.caption)
                                .monospacedDigit()
                        }

                        // Destination
                        Text(departure.headsign)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
        }
    }
}
