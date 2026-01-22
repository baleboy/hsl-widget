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
                            HStack(spacing: 2) {
                                Image(systemName: transitModeIconName(for: departure.mode))
                                    .foregroundColor(transitModeColor(for: departure.mode))
                                    .font(.caption)
                                Text(departure.routeShortName)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .lineLimit(1)
                            }

                            Spacer()

                            // Time with platform and delay badge
                            HStack(spacing: 2) {
                                if let platformCode = departure.platformCode {
                                    Text("P\(platformCode)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                                Text(WidgetViewFormatters.timeFormatter.string(from: entry.displayTime(for: departure)))
                                    .font(.caption)
                                    .monospacedDigit()
                            }
                            .overlay(alignment: .topTrailing) {
                                if !entry.useRealtimeDepartures && departure.shouldShowDelay {
                                    DelayBadgeView(delayMinutes: departure.delayMinutes, font: .system(size: 8, weight: .medium))
                                        .offset(x: 6, y: -4)
                                }
                            }
                            .padding(.trailing, 10)
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
