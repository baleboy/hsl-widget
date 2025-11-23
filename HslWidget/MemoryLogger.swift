//
//  MemoryLogger.swift
//  HslWidget
//
//  Logs memory footprint for debugging widget OOM issues
//

import Foundation

struct MemoryLogger {

    /// Get current memory footprint (what counts toward jetsam limit)
    static func currentMemoryFootprint() -> Double {
        var taskInfo = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size) / 4
        let result = withUnsafeMutablePointer(to: &taskInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }

        guard result == KERN_SUCCESS else {
            return 0
        }

        // phys_footprint is what iOS uses for jetsam decisions
        return Double(taskInfo.phys_footprint) / 1024.0 / 1024.0
    }

    /// Log memory footprint at a specific point
    /// Always logs (even in Release) for memory profiling
    static func log(_ label: String) {
        let memoryMB = currentMemoryFootprint()
        print("MEMORY[\(label)]: \(String(format: "%.1f", memoryMB)) MB (footprint)")
    }
}
