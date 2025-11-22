//
//  WidgetViewFormatters.swift
//  stopInfo
//
//  Created by Claude Code
//

import SwiftUI

/// Shared formatting utilities for widget views
struct WidgetViewFormatters {

    /// Time formatter with leading zeros
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
}

/// Extension to provide dynamic styling based on number of departures
extension TimetableEntry {

    /// Dynamic font size for stop name title based on number of departures
    var titleFont: Font {
        switch departures.count {
        case 1, 2:
            return .headline
        case 3:
            return .caption
        default:
            return .headline
        }
    }

    /// Dynamic font size for route name based on number of departures
    var routeFont: Font {
        switch departures.count {
        case 1, 2:
            return .headline
        case 3:
            return .caption
        default:
            return .headline
        }
    }

    /// Dynamic font size for departure time based on number of departures
    var timeFont: Font {
        switch departures.count {
        case 1, 2:
            return .headline
        case 3:
            return .caption
        default:
            return .headline
        }
    }

    /// Dynamic spacing between departure rows based on number of departures
    var spacing: CGFloat {
        switch departures.count {
        case 1, 2:
            return 3
        case 3:
            return 0
        default:
            return 4
        }
    }
}
