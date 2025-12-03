//
//  StopMapView.swift
//  HslWidget
//
//  Map view for selecting stops with clustering support
//

import SwiftUI
import MapKit
import CoreLocation

struct StopMapView: View {
    let stops: [Stop]
    let favoriteStopIds: Set<String>
    let onToggleFavorite: (Stop) -> Void

    @StateObject private var locationManager = LocationManager.shared
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var selectedStop: Stop?
    @State private var showingStopDetail = false
    @State private var visibleRegion: MKCoordinateRegion?

    // Helsinki city center as fallback
    private let helsinkiCenter = CLLocationCoordinate2D(latitude: 60.1699, longitude: 24.9384)
    private let defaultSpan = MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)

    // Maximum stops to display at once for performance
    private let maxVisibleStops = 100

    var body: some View {
        ZStack {
            mapView
            if showingStopDetail, let stop = selectedStop {
                stopDetailOverlay(stop: stop)
            }
        }
        .onAppear {
            centerOnUserLocation()
        }
    }

    private var mapView: some View {
        Map(position: $cameraPosition) {
            // User location
            UserAnnotation()

            // Only show stops visible in current region
            ForEach(visibleStops) { stop in
                Annotation(
                    stop.name,
                    coordinate: CLLocationCoordinate2D(
                        latitude: stop.latitude!,
                        longitude: stop.longitude!
                    ),
                    anchor: .bottom
                ) {
                    stopMarker(for: stop)
                        .onTapGesture {
                            selectStop(stop)
                        }
                }
                .annotationTitles(.hidden)
            }
        }
        .onMapCameraChange(frequency: .onEnd) { context in
            visibleRegion = context.region
        }
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
        }
    }

    private func stopDetailOverlay(stop: Stop) -> some View {
        VStack {
            Spacer()
            StopDetailSheet(
                stop: stop,
                isFavorite: favoriteStopIds.contains(stop.id),
                distance: formattedDistance(to: stop),
                onToggleFavorite: {
                    onToggleFavorite(stop)
                },
                onDismiss: {
                    showingStopDetail = false
                    selectedStop = nil
                }
            )
            .background(Color(UIColor.systemBackground))
            .cornerRadius(16, corners: [.topLeft, .topRight])
            .shadow(radius: 10)
        }
        .transition(.move(edge: .bottom))
        .animation(.spring(), value: showingStopDetail)
    }

    private func stopMarker(for stop: Stop) -> some View {
        let isFavorite = favoriteStopIds.contains(stop.id)
        let color = markerColor(for: stop)

        return ZStack {
            Circle()
                .fill(color)
                .frame(width: 28, height: 28)

            if isFavorite {
                Image(systemName: "star.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.white)
            } else {
                modeIcon(for: stop)
                    .font(.system(size: 12))
                    .foregroundColor(.white)
            }
        }
        .overlay(
            Circle()
                .stroke(Color.white, lineWidth: 2)
        )
        .shadow(radius: 2)
    }

    private func modeIcon(for stop: Stop) -> some View {
        let mode = (stop.primaryMode ?? stop.vehicleModes?.first)?.uppercased() ?? ""

        return Group {
            switch mode {
            case "BUS":
                Image(systemName: "bus.fill")
            case "TRAM":
                Image(systemName: "tram.fill")
            case "RAIL":
                Image(systemName: "train.side.front.car")
            case "SUBWAY":
                Image(systemName: "train.side.front.car")
            case "FERRY":
                Image(systemName: "ferry.fill")
            default:
                Image(systemName: "circle.fill")
            }
        }
    }

    private func markerColor(for stop: Stop) -> Color {
        if favoriteStopIds.contains(stop.id) {
            return .yellow
        }

        let mode = (stop.primaryMode ?? stop.vehicleModes?.first)?.uppercased() ?? ""

        switch mode {
        case "BUS":
            return .blue
        case "TRAM":
            return .green
        case "RAIL":
            return .purple
        case "SUBWAY":
            return .orange
        case "FERRY":
            return .cyan
        default:
            return .gray
        }
    }

    /// Stops filtered to only those visible in the current map region
    private var visibleStops: [Stop] {
        guard let region = visibleRegion else {
            // No region yet - show stops near user or Helsinki center
            return stopsNearCenter
        }

        let filtered = stops.filter { stop in
            guard let lat = stop.latitude, let lon = stop.longitude else {
                return false
            }
            return isCoordinate(lat: lat, lon: lon, inRegion: region)
        }

        // Limit count for performance, prioritizing favorites
        if filtered.count <= maxVisibleStops {
            return filtered
        }

        let favorites = filtered.filter { favoriteStopIds.contains($0.id) }
        let nonFavorites = filtered.filter { !favoriteStopIds.contains($0.id) }
        let remainingSlots = maxVisibleStops - favorites.count

        return favorites + Array(nonFavorites.prefix(max(0, remainingSlots)))
    }

    /// Initial stops to show before region is determined
    private var stopsNearCenter: [Stop] {
        let center = locationManager.currentLocation?.coordinate
            ?? locationManager.getSharedLocation()?.coordinate
            ?? helsinkiCenter

        return stops
            .filter { $0.latitude != nil && $0.longitude != nil }
            .sorted { stop1, stop2 in
                let dist1 = distanceSquared(from: center, to: stop1)
                let dist2 = distanceSquared(from: center, to: stop2)
                return dist1 < dist2
            }
            .prefix(maxVisibleStops)
            .map { $0 }
    }

    private func isCoordinate(lat: Double, lon: Double, inRegion region: MKCoordinateRegion) -> Bool {
        let latDelta = region.span.latitudeDelta / 2
        let lonDelta = region.span.longitudeDelta / 2

        let minLat = region.center.latitude - latDelta
        let maxLat = region.center.latitude + latDelta
        let minLon = region.center.longitude - lonDelta
        let maxLon = region.center.longitude + lonDelta

        return lat >= minLat && lat <= maxLat && lon >= minLon && lon <= maxLon
    }

    private func distanceSquared(from center: CLLocationCoordinate2D, to stop: Stop) -> Double {
        guard let lat = stop.latitude, let lon = stop.longitude else {
            return Double.greatestFiniteMagnitude
        }
        let dLat = lat - center.latitude
        let dLon = lon - center.longitude
        return dLat * dLat + dLon * dLon
    }

    private func selectStop(_ stop: Stop) {
        selectedStop = stop
        showingStopDetail = true
    }

    private func centerOnUserLocation() {
        let center = locationManager.currentLocation?.coordinate
            ?? locationManager.getSharedLocation()?.coordinate
            ?? helsinkiCenter

        let region = MKCoordinateRegion(center: center, span: defaultSpan)
        cameraPosition = .region(region)
        visibleRegion = region
    }

    private func formattedDistance(to stop: Stop) -> String? {
        guard let currentLocation = locationManager.currentLocation ?? locationManager.getSharedLocation(),
              let lat = stop.latitude,
              let lon = stop.longitude else {
            return nil
        }

        let stopLocation = CLLocation(latitude: lat, longitude: lon)
        let distance = currentLocation.distance(from: stopLocation)

        if distance < 1000 {
            return String(format: "%.0f m", distance)
        } else {
            return String(format: "%.1f km", distance / 1000)
        }
    }
}

// Helper extension for rounded corners on specific sides
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
