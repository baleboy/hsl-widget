//
//  RectangularWidgetView.swift
//  stopInfo
//
//  Created by Claude Code
//

import SwiftUI

/// Rectangular widget layout for lock screen
struct RectangularWidgetView: View {
    let entry: TimetableEntry

    var body: some View {
        VStack(alignment: .leading, spacing: entry.spacing) {
            if entry.departures.isEmpty {
                EmptyStateView(entry: entry)
            } else {
                Text(entry.stopName)
                    .font(entry.titleFont)
                    .widgetAccentable()
                    .lineLimit(1)

                ForEach(entry.departures) { departure in
                    HStack(spacing: 4) {
                        Label(departure.routeShortName, systemImage: transitModeIconName(for: departure.mode))
                            .font(entry.routeFont)
                            .lineLimit(1)
                        Spacer()
                        HStack(spacing: 2) {
                            Text(WidgetViewFormatters.timeFormatter.string(from: departure.departureTime))
                                .font(entry.timeFont)
                                .monospacedDigit()
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                            if departure.shouldShowDelay {
                                Text("+\(departure.delayMinutes)")
                                    .font(entry.timeFont)
                                    .foregroundColor(.red)
                                    .lineLimit(1)
                            }
                        }
                    }
                }
            }
        }
    }
}
