//
//  stopInfo.swift
//  stopInfo
//
//  Created by Francesco Balestrieri on 5.5.2024.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    
    static let stationId = "HSL:1080416"
    static let stationName = "Merisotilaantori"
    static let stationCode = "H0421"
    static let maxNumberOfShownResults = 2
    static let numberOfFetchedResults = 20

    struct TimetableEntry: TimelineEntry {
        let date: Date
        let stopName: String
        let departures: [Departure]
        
        static let example =         TimetableEntry(date: Date(), stopName: "Merisotilaantori", departures: [Departure(departureTime: Date(), routeShortName: "4", headsign: "Munkkiniemi"), Departure(departureTime: Date(), routeShortName: "5", headsign: "Munkkiniemi")])
    }

    func placeholder(in context: Context) -> TimetableEntry {
        TimetableEntry.example
    }

    func getSnapshot(in context: Context, completion: @escaping (TimetableEntry) -> ()) {
        let entry = TimetableEntry.example
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TimetableEntry>) -> ()) {
        
        print("Reloading timeline")
        
        let hslApi = HslApi()
        let defaults = UserDefaults(suiteName: "group.balenet.widget")

        let stopId = defaults?.string(forKey: "selectedStopId") ?? Provider.stationId
        let stopName = defaults?.string(forKey: "selectedStopName") ?? Provider.stationName
        
        print(stopId)
        Task {
            let departures = await hslApi.fetchDepartures(stationId: stopId, numberOfResults: Provider.numberOfFetchedResults)
            
            var entries: [TimetableEntry] = []
            let lastValidIndex = departures.count - Provider.maxNumberOfShownResults
            
            // Iterate over the fetched departures to create timeline entries
            for index in 0..<lastValidIndex {
                let entryDate = (index == 0 ? Date() : departures[index-1].departureTime)
                let nextDepartures = Array(departures[index..<(index + Provider.maxNumberOfShownResults)])
                let entry = TimetableEntry(date: entryDate, stopName: stopName, departures: nextDepartures)
                entries.append(entry)
            }
            
            let timeline = Timeline(entries: entries, policy: .atEnd)
            completion(timeline)
        }
    }
}


struct stopInfoEntryView : View {
    var entry: Provider.Entry
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(entry.stopName)
                .font(.headline)
                .widgetAccentable()
            ForEach(entry.departures) { departure in
                HStack {
                    Label(departure.routeShortName, systemImage: "tram.fill")
                        .font(.headline)
                    Label {
                        Text(departure.departureTime, style: .time)
                    } icon: {
                        Image(systemName: "clock")
                    }.padding(.leading)
                }
            }
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
        .supportedFamilies([.accessoryRectangular, .systemMedium])
    }
}

#Preview(as: .accessoryRectangular) {
    stopInfo()
} timeline: {
    Provider.TimetableEntry.example
}
