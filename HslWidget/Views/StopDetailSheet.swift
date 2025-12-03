//
//  StopDetailSheet.swift
//  HslWidget
//
//  Bottom sheet showing stop details when tapped on the map
//

import SwiftUI
import CoreLocation

struct StopDetailSheet: View {
    let stop: Stop
    let isFavorite: Bool
    let distance: String?
    let onToggleFavorite: () -> Void
    let onDismiss: () -> Void

    @State private var headsigns: [String] = []
    @State private var isLoadingHeadsigns = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerView
            detailsView
            if !headsigns.isEmpty {
                headsignsView
            }
            favoriteButton
        }
        .padding()
        .task {
            await loadHeadsigns()
        }
    }

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(stop.name)
                    .font(.roundedTitle3)
                    .fontWeight(.semibold)
                Text(stop.code)
                    .font(.roundedSubheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
                    .font(.title2)
            }
        }
    }

    private var detailsView: some View {
        HStack(spacing: 12) {
            if let distance = distance {
                Label(distance, systemImage: "location.fill")
                    .font(.roundedSubheadline)
                    .foregroundColor(.secondary)
            }
            if let modes = stop.vehicleModes, !modes.isEmpty {
                HStack(spacing: 4) {
                    // Show primary mode first and prominently
                    if let primary = stop.primaryMode {
                        modeIcon(for: primary, isPrimary: true)
                    }
                    // Show other modes smaller
                    ForEach(Array(modes.sorted().filter { $0 != stop.primaryMode }), id: \.self) { mode in
                        modeIcon(for: mode, isPrimary: false)
                    }
                }
            }
        }
    }

    private var headsignsView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Directions")
                .font(.roundedSubheadline)
                .foregroundColor(.secondary)
            ForEach(headsigns, id: \.self) { headsign in
                HStack(spacing: 4) {
                    Image(systemName: "arrow.right")
                        .font(.roundedCaption)
                        .foregroundColor(.secondary)
                    Text(headsign)
                        .font(.roundedSubheadline)
                }
            }
        }
    }

    private var favoriteButton: some View {
        Button(action: {
            onToggleFavorite()
            onDismiss()
        }) {
            HStack {
                Image(systemName: isFavorite ? "star.slash.fill" : "star.fill")
                Text(isFavorite ? "Remove from Favorites" : "Add to Favorites")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isFavorite ? Color.red.opacity(0.1) : Color.yellow.opacity(0.2))
            .foregroundColor(isFavorite ? .red : .primary)
            .cornerRadius(12)
        }
    }

    private func modeIcon(for mode: String, isPrimary: Bool = false) -> some View {
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
        .font(isPrimary ? .roundedBody : .roundedCaption)
        .opacity(isPrimary ? 1.0 : 0.6)
    }

    private func loadHeadsigns() async {
        guard headsigns.isEmpty else { return }
        isLoadingHeadsigns = true

        let stopIdsToFetch = stop.allStopIds ?? [stop.id]
        var allHeadsigns: [String] = []

        for stopId in stopIdsToFetch {
            let fetched = await HslApi.shared.fetchHeadsigns(stopId: stopId)
            allHeadsigns.append(contentsOf: fetched)
        }

        // Remove duplicates while preserving order
        var uniqueHeadsigns: [String] = []
        var seen = Set<String>()
        for headsign in allHeadsigns {
            if !seen.contains(headsign) {
                uniqueHeadsigns.append(headsign)
                seen.insert(headsign)
            }
        }

        await MainActor.run {
            headsigns = Array(uniqueHeadsigns.prefix(4))
            isLoadingHeadsigns = false
        }
    }
}
