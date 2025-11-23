//
//  WidgetTimelineProvider.swift
//  stopInfo
//
//  Created by Claude Code
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {

    private let timelineBuilder = TimelineBuilder()

    /// Read the number of departures to show from settings
    private var maxNumberOfShownResults: Int {
        let value = UserDefaults(suiteName: "group.balenet.widget")?.integer(forKey: "numberOfDepartures") ?? 0
        return value > 0 ? value : 2
    }

    // MARK: - TimelineProvider

    func placeholder(in context: Context) -> TimetableEntry {
        TimetableEntry.example
    }

    func getSnapshot(in context: Context, completion: @escaping (TimetableEntry) -> ()) {
        completion(TimetableEntry.example)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TimetableEntry>) -> ()) {
        debugLog("========== Widget Timeline Reload ==========")

        let now = Date()

        // Determine how many departures to show based on widget family
        let maxShown = context.family == .systemSmall ? 3 : maxNumberOfShownResults

        // Delegate to timeline builder
        timelineBuilder.buildTimeline(now: now, maxShown: maxShown, completion: completion)
    }
}
