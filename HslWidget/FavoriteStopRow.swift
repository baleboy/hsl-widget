//
//  FavoriteStopRow.swift
//  HslWidget
//
//  Row view for displaying a favorite stop with its details
//

import SwiftUI

struct FavoriteStopRow: View {
    let stop: Stop
    let isClosest: Bool
    let filteredHeadsigns: [String]?
    let linesByMode: [String: [String]]?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 4) {
                // Header with stop name and indicators
                HStack {
                    Text(stop.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                    if stop.hasFilters {
                        Image(systemName: "line.3.horizontal.decrease.circle.fill")
                            .foregroundColor(.blue)
                            .font(.caption)
                    }
                    if isClosest {
                        Image(systemName: "location.fill")
                            .foregroundColor(.blue)
                            .font(.caption)
                    }
                }

                // Stop code and filter indicator
                HStack {
                    Text(stop.code)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if stop.hasFilters {
                        Text("• Filtered")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }

                // Headsigns for filtered lines
                if let headsigns = filteredHeadsigns, !headsigns.isEmpty {
                    HeadsignList(headsigns: headsigns, isFiltered: true)
                }
                // All headsigns if no line filter
                else if let headsigns = stop.headsigns,
                        !headsigns.isEmpty,
                        stop.filteredLines == nil || stop.filteredLines!.isEmpty {
                    HeadsignList(headsigns: headsigns, isFiltered: false)
                }

                // Lines grouped by mode
                if let linesByMode = linesByMode, !linesByMode.isEmpty {
                    LinesByMode(linesByMode: linesByMode, isFiltered: stop.hasFilters)
                }

                // Filtered headsign pattern
                if let pattern = stop.filteredHeadsignPattern, !pattern.isEmpty {
                    HeadsignPattern(pattern: pattern)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
