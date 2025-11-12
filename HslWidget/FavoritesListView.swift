//
//  FavoritesListView.swift
//  HslWidget
//
//  Main view showing favorite stops with button to add more
//

import SwiftUI

struct FavoritesListView: View {
    @State private var favorites: [Stop] = []
    @State private var showingStopPicker = false
    @StateObject private var locationManager = LocationManager.shared

    private let favoritesManager = FavoritesManager.shared

    var body: some View {
        NavigationView {
            VStack {
                if favorites.isEmpty {
                    // Empty state
                    VStack(spacing: 16) {
                        Image(systemName: "star.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("No favorite stops selected")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Text("Tap the button below to select your favorite stops")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    // List of favorites
                    List {
                        ForEach(favorites) { stop in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(stop.name)
                                        .font(.headline)
                                    Spacer()
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.yellow)
                                }
                                Text(stop.code)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    removeFavorite(stop)
                                } label: {
                                    Label("Remove", systemImage: "trash")
                                }
                            }
                        }
                    }
                }

                // Add favorites button
                Button(action: {
                    showingStopPicker = true
                }) {
                    Label(favorites.isEmpty ? "Select Favorites" : "Add More Favorites", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding()
                }
            }
            .navigationTitle("Favorite Stops")
            .onAppear {
                loadFavorites()
                requestLocationPermission()
            }
            .sheet(isPresented: $showingStopPicker) {
                StopPickerView(onDismiss: {
                    showingStopPicker = false
                    loadFavorites()
                })
            }
        }
    }

    private func loadFavorites() {
        favorites = favoritesManager.getFavorites()
        print("FavoritesListView: Loaded \(favorites.count) favorites")
    }

    private func removeFavorite(_ stop: Stop) {
        favoritesManager.removeFavorite(stop)
        loadFavorites()
    }

    private func requestLocationPermission() {
        print("FavoritesListView: Requesting location permission")
        locationManager.requestPermission()
    }
}

#Preview {
    FavoritesListView()
}
