//
//  InlineWidgetView.swift
//  stopInfo
//
//  Created by Claude Code
//

import SwiftUI

/// Compact view for inline widget showing only the next departure
struct InlineWidgetView: View {
    let entry: TimetableEntry

    var body: some View {
        if let nextDeparture = entry.departures.first {
            Label {
                Text("\(nextDeparture.routeShortName)•\(WidgetViewFormatters.timeFormatter.string(from: nextDeparture.departureTime))")
            } icon: {
                Image(systemName: transitModeIconName(for: nextDeparture.mode, filled: false))
            }
        } else {
            Label {
                Text(entry.state == .noFavorites ? "No favorites" : "No departures")
            } icon: {
                Image(systemName: "tram")
            }
        }
    }
}
