//
//  StopDetailsHelpers.swift
//  HslWidget
//
//  Helper views for displaying stop details (headsigns, lines, modes)
//

import SwiftUI

/// Displays a list of headsigns with an arrow icon
struct HeadsignList: View {
    let headsigns: [String]
    let isFiltered: Bool

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "arrow.right")
                .font(.caption2)
                .foregroundColor(isFiltered ? .blue : .secondary)
            Text(headsigns.prefix(3).joined(separator: ", "))
                .font(.caption)
                .foregroundColor(isFiltered ? .blue : .secondary)
                .lineLimit(1)
        }
        .padding(.top, 2)
    }
}

/// Displays a filtered headsign pattern
struct HeadsignPattern: View {
    let pattern: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "arrow.right")
                .font(.caption2)
                .foregroundColor(.blue)
            Text("To: \(pattern)")
                .font(.caption)
                .foregroundColor(.blue)
                .lineLimit(1)
        }
        .padding(.top, 2)
    }
}

/// Displays lines grouped by mode (bus, tram, etc.)
struct LinesByMode: View {
    let linesByMode: [String: [String]]
    let isFiltered: Bool

    var body: some View {
        HStack(spacing: 6) {
            ForEach(Array(linesByMode.keys.sorted()), id: \.self) { mode in
                if let lines = linesByMode[mode], !lines.isEmpty {
                    HStack(spacing: 2) {
                        TransitModeIcon(mode: mode)
                        Text(lines.sorted().joined(separator: ", "))
                            .font(.caption)
                            .foregroundColor(isFiltered ? .blue : .secondary)
                    }
                }
            }
        }
        .padding(.top, 2)
    }
}

/// Transit mode icon (bus, tram, train, etc.)
struct TransitModeIcon: View {
    let mode: String

    var body: some View {
        Group {
            switch mode.uppercased() {
            case "BUS":
                Image(systemName: "bus.fill")
                    .foregroundColor(.blue)
            case "TRAM":
                Image(systemName: "tram.fill")
                    .foregroundColor(.green)
            case "RAIL":
                Image(systemName: "train.side.front.car")
                    .foregroundColor(.purple)
            case "SUBWAY":
                Image(systemName: "train.side.front.car")
                    .foregroundColor(.orange)
            case "FERRY":
                Image(systemName: "ferry.fill")
                    .foregroundColor(.cyan)
            default:
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(.gray)
            }
        }
        .font(.caption)
    }
}
