//
//  DebugLogger.swift
//  HslWidget
//
//  Debug logging utility that only prints in debug builds
//

import Foundation

/// Prints debug messages only in DEBUG builds
/// In release builds, this function does nothing
func debugLog(_ message: String) {
    #if DEBUG
    print(message)
    #endif
}
