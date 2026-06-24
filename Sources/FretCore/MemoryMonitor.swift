import Foundation

/// Watches memory pressure via Mach `host_statistics64`. "Used" here is the
/// pressure-relevant footprint — wired + active + compressed — over physical
/// RAM, which tracks Activity Monitor's green/yellow/red feel closely enough.
public struct MemoryMonitor: Monitor {
    public let id = "memory"
    public let label = "Memory"
    public let icon = "🧠"
    public init() {}

    public func sample() -> Reading {
        guard let pct = Self.usedFraction() else { return Reading(mood: .chill, value: "?") }
        return Reading(mood: .fromHealth(1 - pct),                       // less used = healthier
                       value: String(format: "%.0f%%", pct * 100),         // templates may add "used"
                       display: String(format: "%.0f%% used", pct * 100))
    }

    /// Fraction of physical RAM under pressure (0…1), or nil on failure.
    static func usedFraction() -> Double? {
        let total = Double(ProcessInfo.processInfo.physicalMemory)
        guard total > 0 else { return nil }

        var stats = vm_statistics64_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.stride / MemoryLayout<integer_t>.stride)
        let kr = withUnsafeMutablePointer(to: &stats) { ptr -> kern_return_t in
            ptr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        guard kr == KERN_SUCCESS else { return nil }

        let page = Double(vm_kernel_page_size)
        let wired      = Double(stats.wire_count) * page
        let active     = Double(stats.active_count) * page
        let compressed = Double(stats.compressor_page_count) * page
        return min(1.0, (wired + active + compressed) / total)
    }
}
