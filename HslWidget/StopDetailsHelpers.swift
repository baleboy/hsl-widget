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
                .font(.roundedCaption2)
                .foregroundColor(isFiltered ? .blue : .secondary)
            Text(headsigns.prefix(3).joined(separator: ", "))
                .font(.roundedCaption)
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
                .font(.roundedCaption2)
                .foregroundColor(.blue)
            Text("To: \(pattern)")
                .font(.roundedCaption)
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
                            .font(.roundedCaption)
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
        .font(.roundedCaption)
    }
}

#Preview("Headsign List - Filtered") {
    VStack(alignment: .leading) {
        HeadsignList(headsigns: ["Pasila", "Kamppi", "Erottaja"], isFiltered: true)
    }
    .padding()
}

#Preview("Headsign List - Unfiltered") {
    VStack(alignment: .leading) {
        HeadsignList(headsigns: ["Pasila", "Kamppi", "Erottaja"], isFiltered: false)
    }
    .padding()
}

#Preview("Headsign Pattern") {
    VStack(alignment: .leading) {
        HeadsignPattern(pattern: "Kamppi")
    }
    .padding()
}

#Preview("Lines By Mode - Single") {
    VStack(alignment: .leading) {
        LinesByMode(linesByMode: ["TRAM": ["6", "9"]], isFiltered: false)
    }
    .padding()
}

#Preview("Lines By Mode - Multiple") {
    VStack(alignment: .leading) {
        LinesByMode(
            linesByMode: [
                "BUS": ["40", "55"],
                "TRAM": ["2", "3", "4", "5", "6", "7", "9"],
                "SUBWAY": ["M1", "M2"]
            ],
            isFiltered: true
        )
    }
    .padding()
}

#Preview("Transit Mode Icons") {
    VStack(alignment: .leading, spacing: 8) {
        HStack {
            TransitModeIcon(mode: "BUS")
            Text("Bus")
        }
        HStack {
            TransitModeIcon(mode: "TRAM")
            Text("Tram")
        }
        HStack {
            TransitModeIcon(mode: "RAIL")
            Text("Rail")
        }
        HStack {
            TransitModeIcon(mode: "SUBWAY")
            Text("Subway")
        }
        HStack {
            TransitModeIcon(mode: "FERRY")
            Text("Ferry")
        }
    }
    .padding()
}
