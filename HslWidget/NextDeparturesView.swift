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
                        HStack {
                            Label(departure.routeShortName, systemImage: transitModeIconName(for: departure.mode))
                                .font(.roundedHeadline)
                            Spacer()
                            Text(departure.departureTime, style: .time)
                                .font(.roundedHeadline)
                                .monospacedDigit()
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
                Departure(departureTime: Date().addingTimeInterval(180), routeShortName: "9", headsign: "Pasila", mode: "TRAM"),
                Departure(departureTime: Date().addingTimeInterval(420), routeShortName: "9", headsign: "Pasila", mode: "TRAM"),
                Departure(departureTime: Date().addingTimeInterval(600), routeShortName: "6", headsign: "Arabianranta", mode: "TRAM")
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
