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
    @State private var favoriteStopIds = Set<String>()
    @StateObject private var locationManager = LocationManager.shared

    private let favoritesManager = FavoritesManager.shared

    var filteredStops: [Stop] {
        guard !searchTerm.isEmpty else {
            return stops
        }
        return stops.filter {
            $0.name.localizedCaseInsensitiveContains(searchTerm) ||
            $0.code.localizedCaseInsensitiveContains(searchTerm)
        }
    }

    var favoritesSection: [Stop] {
        stops.filter { favoriteStopIds.contains($0.id) }
    }

    var body: some View {
        NavigationView {
            if stops.isEmpty {
                Text("Loading...").font(.title)
            } else {
                List {
                    // Show favorites section if there are any
                    if !favoritesSection.isEmpty && searchTerm.isEmpty {
                        Section(header: Text("Favorites")) {
                            ForEach(favoritesSection) { stop in
                                stopRow(stop)
                            }
                        }
                    }

                    Section(header: searchTerm.isEmpty ? Text("All Stops") : nil) {
                        ForEach(filteredStops) { stop in
                            // Skip stops already shown in favorites section
                            if searchTerm.isEmpty && favoriteStopIds.contains(stop.id) {
                                EmptyView()
                            } else {
                                stopRow(stop)
                            }
                        }
                    }
                }
                .searchable(text: $searchTerm, prompt: "Search by name or code")
                .navigationBarTitle("Favorite Stops")
                .onAppear {
                    loadFavorites()
                    requestLocationPermission()
                }
            }
        }
        .task {
            stops = await HslApi.shared.fetchAllStops()
        }
    }

    private func stopRow(_ stop: Stop) -> some View {
        Button(action: {
            toggleFavorite(stop)
        }) {
            HStack {
                VStack(alignment: .leading) {
                    Text(stop.name)
                    Text(stop.code).font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                if favoriteStopIds.contains(stop.id) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func toggleFavorite(_ stop: Stop) {
        print("UI: Toggling favorite for: \(stop.name)")
        favoritesManager.toggleFavorite(stop)
        loadFavorites()
        print("UI: Current favorites count: \(favoriteStopIds.count)")
    }

    private func loadFavorites() {
        let favorites = favoritesManager.getFavorites()
        favoriteStopIds = Set(favorites.map { $0.id })
        print("UI: Loaded \(favoriteStopIds.count) favorites")
    }

    private func requestLocationPermission() {
        print("UI: Requesting location permission")
        locationManager.requestPermission()
    }
}

#Preview {
    StopSelectionView()
}

