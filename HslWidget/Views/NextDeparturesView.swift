//
//  NextDeparturesView.swift
//  HslWidget
//
//  Section showing next departures for the closest favorite stop
//

import SwiftUI

struct NextDeparturesView: View {
    let stop: Stop
    let departures: [Departure]
    let isLoading: Bool

    var body: some View {
        Section(header: Text("Next Departures")) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundColor(.blue)
                        .font(.roundedCaption)
                    Text(stop.name)
                        .font(.roundedHeadline)
                }

                if isLoading {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Loading...")
                            .font(.roundedCaption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                } else if departures.isEmpty {
                    Text("No departures available")
                        .font(.roundedCaption)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 4)
                } else {
                    ForEach(departures.prefix(3)) { departure in
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Label {
                                    Text(departure.routeShortName)
                                } icon: {
                                    Image(systemName: transitModeIconName(for: departure.mode))
                                        .foregroundColor(transitModeColor(for: departure.mode))
                                }
                                .font(.roundedHeadline)
                                Spacer()
                                Text(departure.departureTime, style: .time)
                                    .font(.roundedHeadline)
                                    .monospacedDigit()
                            }

                            // Destination with optional delay info
                            if departure.shouldShowDelay {
                                Text("\(departure.headsign) · \(departure.delayMinutes) \(String(localized: "min late"))")
                                    .font(.roundedCaption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            } else {
                                Text(departure.headsign)
                                    .font(.roundedCaption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
}

#Preview("With Departures") {
    List {
        NextDeparturesView(
            stop: Stop.defaultStop,
            departures: [
                Departure(departureTime: Date().addingTimeInterval(180), routeShortName: "9", headsign: "Pasila", mode: "TRAM", delaySeconds: 240),
                Departure(departureTime: Date().addingTimeInterval(420), routeShortName: "9", headsign: "Pasila", mode: "TRAM"),
                Departure(departureTime: Date().addingTimeInterval(600), routeShortName: "6", headsign: "Arabianranta", mode: "TRAM", delaySeconds: 180)
            ],
            isLoading: false
        )
    }
}

#Preview("Loading") {
    List {
        NextDeparturesView(
            stop: Stop.defaultStop,
            departures: [],
            isLoading: true
        )
    }
}

#Preview("Empty") {
    List {
        NextDeparturesView(
            stop: Stop.defaultStop,
            departures: [],
            isLoading: false
        )
    }
}
