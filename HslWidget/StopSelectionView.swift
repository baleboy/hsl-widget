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
    @State private var selectedStopIds = Set<String>()

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
                List(filteredStops) { stop in
                    Button(action: {
                        toggleSelection(for: stop)
                    }) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(stop.name)
                                Text(stop.code).font(.caption)
                            }
                            Spacer()
                            Image(systemName: selectedStopIds.contains(stop.id) ? "star.fill" : "star")
                                .foregroundColor(selectedStopIds.contains(stop.id) ? .accentColor : .secondary)
                        }
                    }
                }
                .searchable(text: $searchTerm, prompt: "Search by name or code")
                .navigationBarTitle("Select Favorite Stops")
            }
        }
        .task {
            stops = await HslApi.shared.fetchAllStops()
            loadFavoriteStops()
        }
    }

    private func toggleSelection(for stop: Stop) {
        if selectedStopIds.contains(stop.id) {
            selectedStopIds.remove(stop.id)
        } else {
            selectedStopIds.insert(stop.id)
        }
        saveFavoriteStops()
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func saveFavoriteStops() {
        let favorites = stops.filter { selectedStopIds.contains($0.id) }
        FavoriteStopsStore.save(favorites, to: sharedDefaults)
    }

    private func loadFavoriteStops() {
        let favorites = FavoriteStopsStore.load(from: sharedDefaults)
        let availableIds = Set(stops.map { $0.id })
        var ids = Set(favorites.map { $0.id }).intersection(availableIds)

        if ids.isEmpty,
           let legacyStop = FavoriteStopsStore.loadLegacyStop(from: sharedDefaults),
           availableIds.contains(legacyStop.id) {
            ids.insert(legacyStop.id)
        }

        selectedStopIds = ids
    }

}

#Preview {
    StopSelectionView()
}

