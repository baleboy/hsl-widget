//
//  StopAnnotationView.swift
//  HslWidget
//
//  Custom annotation view for displaying stops on the map
//

import SwiftUI

struct StopAnnotationView: View {
    let stop: Stop
    let isFavorite: Bool

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Main marker with transport mode icon
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(markerColor)
                        .frame(width: 30, height: 30)

                    primaryModeIcon
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                }

                // Pin tail
                Triangle()
                    .fill(markerColor)
                    .frame(width: 10, height: 8)
                    .offset(y: -1)
            }

            // Favorite star badge
            if isFavorite {
                Image(systemName: "star.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.yellow)
                    .background(
                        Circle()
                            .fill(.white)
                            .frame(width: 14, height: 14)
                    )
                    .offset(x: 4, y: -4)
            }
        }
    }

    private var markerColor: Color {
        isFavorite ? .blue : .gray
    }

    private var primaryModeIcon: some View {
        Group {
            if let modes = stop.vehicleModes, !modes.isEmpty {
                // Show icon for primary mode (first in sorted order)
                let primaryMode = modes.sorted().first!
                modeIcon(for: primaryMode)
            } else {
                Image(systemName: "mappin")
            }
        }
    }

    private func modeIcon(for mode: String) -> some View {
        Group {
            switch mode.uppercased() {
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
                Image(systemName: "mappin")
            }
        }
    }
}

/// Triangle shape for pin tail
private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

#Preview {
    VStack(spacing: 20) {
        StopAnnotationView(
            stop: Stop(id: "1", name: "Test Stop", code: "T123", vehicleModes: ["BUS"]),
            isFavorite: false
        )

        StopAnnotationView(
            stop: Stop(id: "2", name: "Favorite Stop", code: "T456", vehicleModes: ["TRAM"]),
            isFavorite: true
        )
    }
    .padding()
}
