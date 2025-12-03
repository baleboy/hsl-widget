//
//  StopMapView.swift
//  HslWidget
//
//  Map view for selecting favorite stops
//

import SwiftUI
import MapKit
import CoreLocation

struct StopMapView: View {
    let stops: [Stop]
    @Binding var searchTerm: String
    @Binding var favoriteStopIds: Set<String>
    let onToggleFavorite: (Stop) -> Void

    @StateObject private var locationManager = LocationManager.shared
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var selectedStopId: String?
    @State private var mapRegion: MKCoordinateRegion?

    // Only show stops within radius when not searching (for performance)
    private let maxDisplayRadius: Double = 10000 // 10km - wider radius to show clustering

    var displayedStops: [Stop] {
        if !searchTerm.isEmpty {
            // When searching, show all matching stops
            return stops.filter {
                $0.name.localizedCaseInsensitiveContains(searchTerm) ||
                $0.code.localizedCaseInsensitiveContains(searchTerm)
            }
        }

        // When not searching, only show nearby stops for performance
        guard let userLocation = locationManager.currentLocation ?? locationManager.getSharedLocation() else {
            // No location - show first 100 stops
            return Array(stops.prefix(100))
        }

        return stops.filter { stop in
            guard let lat = stop.latitude, let lon = stop.longitude else { return false }
            let stopLocation = CLLocation(latitude: lat, longitude: lon)
            let distance = userLocation.distance(from: stopLocation)
            return distance <= maxDisplayRadius
        }
    }

    // Cluster stops based on current zoom level
    var clusteredStops: [ClusterItem] {
        guard let region = mapRegion else {
            // Initial load - show individual stops
            return displayedStops.map { .single($0) }
        }

        // Calculate cluster distance based on zoom level (in degrees)
        let clusterDistance = region.span.latitudeDelta * 0.08 // 8% of visible span

        var clusters: [ClusterItem] = []
        var processedStops = Set<String>()

        for stop in displayedStops {
            guard !processedStops.contains(stop.id),
                  let stopCoord = stopCoordinate(stop) else { continue }

            // Find nearby stops within cluster distance
            let nearbyStops = displayedStops.filter { otherStop in
                guard !processedStops.contains(otherStop.id),
                      let otherCoord = stopCoordinate(otherStop) else { return false }

                let latDiff = abs(stopCoord.latitude - otherCoord.latitude)
                let lonDiff = abs(stopCoord.longitude - otherCoord.longitude)

                return latDiff < clusterDistance && lonDiff < clusterDistance
            }

            // Mark all stops in this cluster as processed
            nearbyStops.forEach { processedStops.insert($0.id) }

            if nearbyStops.count > 1 {
                // Create cluster
                clusters.append(.cluster(nearbyStops))
            } else {
                // Single stop
                clusters.append(.single(stop))
            }
        }

        return clusters
    }

    enum ClusterItem: Identifiable {
        case single(Stop)
        case cluster([Stop])

        var id: String {
            switch self {
            case .single(let stop):
                return stop.id
            case .cluster(let stops):
                return stops.map { $0.id }.joined(separator: ",")
            }
        }

        var coordinate: CLLocationCoordinate2D? {
            switch self {
            case .single(let stop):
                guard let lat = stop.latitude, let lon = stop.longitude else { return nil }
                return CLLocationCoordinate2D(latitude: lat, longitude: lon)
            case .cluster(let stops):
                let coords = stops.compactMap { stop -> CLLocationCoordinate2D? in
                    guard let lat = stop.latitude, let lon = stop.longitude else { return nil }
                    return CLLocationCoordinate2D(latitude: lat, longitude: lon)
                }
                guard !coords.isEmpty else { return nil }
                let avgLat = coords.map { $0.latitude }.reduce(0, +) / Double(coords.count)
                let avgLon = coords.map { $0.longitude }.reduce(0, +) / Double(coords.count)
                return CLLocationCoordinate2D(latitude: avgLat, longitude: avgLon)
            }
        }

        var count: Int {
            switch self {
            case .single:
                return 1
            case .cluster(let stops):
                return stops.count
            }
        }

        var hasFavorite: Bool {
            switch self {
            case .single:
                return false // Will be determined from binding
            case .cluster:
                return false // Will be determined from binding
            }
        }
    }

    var body: some View {
        Map(position: $cameraPosition) {
            // User location
            UserAnnotation()

            // Render clustered stops
            ForEach(clusteredStops) { item in
                if let coordinate = item.coordinate {
                    switch item {
                    case .single(let stop):
                        // Individual stop marker
                        Annotation(stop.name, coordinate: coordinate) {
                            Button(action: {
                                onToggleFavorite(stop)
                            }) {
                                Image(systemName: favoriteStopIds.contains(stop.id) ? "star.circle.fill" : "circle.fill")
                                    .font(.title3)
                                    .foregroundColor(favoriteStopIds.contains(stop.id) ? .yellow : .blue)
                                    .background(
                                        Circle()
                                            .fill(.white)
                                            .frame(width: 20, height: 20)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                        .annotationTitles(.hidden)

                    case .cluster(let stops):
                        // Cluster marker showing count
                        Annotation("", coordinate: coordinate) {
                            Button(action: {
                                // Zoom in to expand cluster
                                zoomToStops(stops)
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(stops.contains(where: { favoriteStopIds.contains($0.id) }) ? Color.yellow : Color.blue)
                                        .frame(width: 40, height: 40)

                                    Text("\(stops.count)")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                .shadow(radius: 3)
                            }
                            .buttonStyle(.plain)
                        }
                        .annotationTitles(.hidden)
                    }
                }
            }
        }
        .mapStyle(.standard(elevation: .flat))
        .mapControls {
            MapUserLocationButton()
            MapCompass()
        }
        .onAppear {
            centerOnUserLocation()
        }
        .onChange(of: searchTerm) { oldValue, newValue in
            updateMapRegion(for: newValue)
        }
        .onMapCameraChange { context in
            mapRegion = context.region
        }
    }

    private func stopCoordinate(_ stop: Stop) -> CLLocationCoordinate2D? {
        guard let lat = stop.latitude, let lon = stop.longitude else {
            return nil
        }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    private func centerOnUserLocation() {
        if let location = locationManager.currentLocation ?? locationManager.getSharedLocation() {
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.15, longitudeDelta: 0.15) // Zoomed out more to show clustering
                )
            )
        }
    }

    private func zoomToStops(_ stops: [Stop]) {
        let coordinates = stops.compactMap { stopCoordinate($0) }
        guard !coordinates.isEmpty else { return }

        let region = calculateRegion(for: coordinates)
        // Zoom in a bit more to expand the cluster
        let zoomedRegion = MKCoordinateRegion(
            center: region.center,
            span: MKCoordinateSpan(
                latitudeDelta: region.span.latitudeDelta * 0.5,
                longitudeDelta: region.span.longitudeDelta * 0.5
            )
        )
        withAnimation {
            cameraPosition = .region(zoomedRegion)
        }
    }

    private func updateMapRegion(for searchTerm: String) {
        if searchTerm.isEmpty {
            // Return to user location when search is cleared
            centerOnUserLocation()
        } else {
            // Zoom to fit all displayed stops
            zoomToFitDisplayedStops()
        }
    }

    private func zoomToFitDisplayedStops() {
        let coordinates = displayedStops.compactMap { stopCoordinate($0) }

        guard !coordinates.isEmpty else { return }

        if coordinates.count == 1 {
            // Single result - center on it
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: coordinates[0],
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
            )
        } else {
            // Multiple results - fit all
            let region = calculateRegion(for: coordinates)
            cameraPosition = .region(region)
        }
    }

    private func calculateRegion(for coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion {
        var minLat = coordinates[0].latitude
        var maxLat = coordinates[0].latitude
        var minLon = coordinates[0].longitude
        var maxLon = coordinates[0].longitude

        for coordinate in coordinates {
            minLat = min(minLat, coordinate.latitude)
            maxLat = max(maxLat, coordinate.latitude)
            minLon = min(minLon, coordinate.longitude)
            maxLon = max(maxLon, coordinate.longitude)
        }

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )

        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) * 1.5, 0.01),
            longitudeDelta: max((maxLon - minLon) * 1.5, 0.01)
        )

        return MKCoordinateRegion(center: center, span: span)
    }
}

#Preview {
    StopMapView(
        stops: [
            Stop(id: "1", name: "Kamppi", code: "H1234", latitude: 60.168992, longitude: 24.931984, vehicleModes: ["BUS"]),
            Stop(id: "2", name: "Rautatientori", code: "H1301", latitude: 60.170877, longitude: 24.943353, vehicleModes: ["TRAM"])
        ],
        searchTerm: .constant(""),
        favoriteStopIds: .constant(["1"]),
        onToggleFavorite: { _ in }
    )
}
