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
                        .font(.roundedHeadline)
                        .foregroundColor(.primary)
                    Spacer()
                    if stop.hasFilters {
                        Image(systemName: "line.3.horizontal.decrease.circle.fill")
                            .foregroundColor(.blue)
                            .font(.roundedCaption)
                    }
                    if isClosest {
                        Image(systemName: "location.fill")
                            .foregroundColor(.blue)
                            .font(.roundedCaption)
                    }
                }

                // Stop code and filter indicator
                HStack {
                    Text(stop.code)
                        .font(.roundedCaption)
                        .foregroundColor(.secondary)
                    if stop.hasFilters {
                        Text("• Filtered")
                            .font(.roundedCaption)
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

#Preview("Basic Stop") {
    List {
        FavoriteStopRow(
            stop: Stop.defaultStop,
            isClosest: false,
            filteredHeadsigns: nil,
            linesByMode: ["TRAM": ["6", "9"]],
            onTap: {}
        )
    }
}

#Preview("Closest Stop") {
    List {
        FavoriteStopRow(
            stop: Stop.defaultStop,
            isClosest: true,
            filteredHeadsigns: nil,
            linesByMode: ["TRAM": ["6", "9"]],
            onTap: {}
        )
    }
}

#Preview("Filtered Stop") {
    List {
        FavoriteStopRow(
            stop: Stop(
                id: "HSL:1080416",
                name: "Merisotilaantori",
                code: "H0421",
                latitude: 60.159,
                longitude: 24.9208,
                vehicleModes: ["TRAM"],
                headsigns: ["Pasila", "Arabianranta"],
                allStopIds: nil,
                filteredLines: ["9"],
                filteredHeadsignPattern: nil
            ),
            isClosest: false,
            filteredHeadsigns: ["Pasila"],
            linesByMode: ["TRAM": ["9"]],
            onTap: {}
        )
    }
}

#Preview("Multiple Modes") {
    List {
        FavoriteStopRow(
            stop: Stop(
                id: "HSL:1020450",
                name: "Rautatientori",
                code: "H0011",
                latitude: 60.169,
                longitude: 24.940,
                vehicleModes: ["BUS", "TRAM"],
                headsigns: ["Erottaja", "Kamppi", "Pasila"],
                allStopIds: nil,
                filteredLines: nil,
                filteredHeadsignPattern: nil
            ),
            isClosest: true,
            filteredHeadsigns: nil,
            linesByMode: ["BUS": ["40", "55"], "TRAM": ["2", "3", "4", "5", "6", "7", "9"]],
            onTap: {}
        )
    }
}
