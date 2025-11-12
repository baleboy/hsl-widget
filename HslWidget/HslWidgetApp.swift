//
//  HslWidgetApp.swift
//  HslWidget
//
//  Created by Francesco Balestrieri on 4.5.2024.
//

import SwiftUI

@main
struct HslWidgetApp: App {
    init() {
        // Clean up old data format from previous version
        cleanupOldData()

        // Initialize location manager on app launch
        _ = LocationManager.shared
    }

    var body: some Scene {
        WindowGroup {
            FavoritesListView()
        }
    }

    private func cleanupOldData() {
        let defaults = UserDefaults(suiteName: "group.balenet.widget")

        // Remove old single-stop selection keys
        defaults?.removeObject(forKey: "selectedStopId")
        defaults?.removeObject(forKey: "selectedStopName")

        print("Cleaned up old UserDefaults data")
    }
}
