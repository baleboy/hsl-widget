//
//  StopPickerView.swift
//  HslWidget
//
//  Created by Francesco Balestrieri on 8.5.2024.
//

import SwiftUI
import WidgetKit

struct StopSelectionView: View {
    @State private var stops = [Stop]()
    @State private var searchTerm = ""
    @State var selectedStop: Stop? = nil
    
    private let hslApi = HslApi()
    private let sharedDefaults = UserDefaults(suiteName: "group.balenet.widget")
    
    var filteredStops: [Stop] {
        guard !searchTerm.isEmpty else {
            return stops
        }
        return stops.filter {
            $0.name.localizedCaseInsensitiveContains(searchTerm) ||
            $0.code.localizedCaseInsensitiveContains(searchTerm)
        }
    }

    var body: some View {
        NavigationView {
            if stops.isEmpty {
                Text("Loading...").font(.title)
            } else {
                ScrollViewReader { proxy in
                    List(filteredStops) { stop in
                        Button(action: {
                            selectStop(stop)
                        }) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(stop.name)
                                    Text(stop.code).font(.caption)
                                }
                                Spacer()
                                if selectedStop?.id == stop.id {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                    }
                    .searchable(text: $searchTerm, prompt: "Search by name or code")
                    .navigationBarTitle("Select a Stop")
                    .onAppear {
                        loadSelectedStopId(with: proxy)
                    }
                }
            }
        }
        .task {
            stops = await hslApi.fetchAllStops()
        }
    }
    
    private func selectStop(_ stop: Stop) {
        selectedStop = stop
        saveSelectedStopData(stop)
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func saveSelectedStopData(_ stop: Stop) {
        sharedDefaults?.set(stop.id, forKey: "selectedStopId")
        sharedDefaults?.set(stop.name, forKey: "selectedStopName")
    }
    
    private func loadSelectedStopId(with scrollProxy: ScrollViewProxy) {
        if let stopId = sharedDefaults?.string(forKey: "selectedStopId"),
           let stop = stops.first(where: { $0.id == stopId }) {
            selectedStop = stop
            withAnimation {
                scrollProxy.scrollTo(stop.id, anchor: .top)
            }
        }
    }
}

#Preview {
    StopSelectionView()
}

