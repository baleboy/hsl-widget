//
//  stopInfo.swift
//  stopInfo
//
//  Created by Francesco Balestrieri on 5.5.2024.
//

import WidgetKit
import SwiftUI

struct stopInfoEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryInline:
            InlineWidgetView(entry: entry)
        case .systemSmall:
            SystemSmallWidgetView(entry: entry)
        default:
            // Rectangular widgets show compact layout
            RectangularWidgetView(entry: entry)
        }
    }
}

struct stopInfo: Widget {
    let kind: String = "stopInfo"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                stopInfoEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                stopInfoEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("My Widget")
        .description("This is an example widget.")
        .supportedFamilies([.accessoryRectangular, .accessoryInline, .systemSmall])
    }
}

#Preview("1 Departure", as: .accessoryRectangular) {
    stopInfo()
} timeline: {
    TimetableEntry.example1Departure
}

#Preview("2 Departures", as: .accessoryRectangular) {
    stopInfo()
} timeline: {
    TimetableEntry.example2Departures
}

#Preview("3 Departures", as: .accessoryRectangular) {
    stopInfo()
} timeline: {
    TimetableEntry.example3Departures
}

#Preview("Inline", as: .accessoryInline) {
    stopInfo()
} timeline: {
    TimetableEntry.example1Departure
}

#Preview("Home Screen", as: .systemSmall) {
    stopInfo()
} timeline: {
    TimetableEntry.example4Departures
}
