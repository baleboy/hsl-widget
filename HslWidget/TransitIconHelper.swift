//
//  TransitIconHelper.swift
//  HslWidget
//
//  UI helper for transit mode icons
//

import SwiftUI

/// Get SF Symbol icon name based on transportation mode
/// - Parameters:
///   - mode: The transportation mode (BUS, TRAM, RAIL, etc.)
///   - filled: Whether to use filled variant (default: true)
/// - Returns: SF Symbol name for the icon
func transitModeIconName(for mode: String?, filled: Bool = true) -> String {
    let modeUpper = mode?.uppercased() ?? ""
    let suffix = filled ? ".fill" : ""

    switch modeUpper {
    case "BUS":
        return "bus\(suffix)"
    case "TRAM":
        return "tram\(suffix)"
    case "RAIL":
        return "train.side.front.car"
    case "SUBWAY":
        return "train.side.front.car"
    case "FERRY":
        return "ferry\(suffix)"
    default:
        return "tram\(suffix)"
    }
}

/// Get color for transportation mode
/// - Parameter mode: The transportation mode (BUS, TRAM, RAIL, etc.)
/// - Returns: SwiftUI Color for the mode
func transitModeColor(for mode: String?) -> Color {
    let modeUpper = mode?.uppercased() ?? ""

    switch modeUpper {
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
