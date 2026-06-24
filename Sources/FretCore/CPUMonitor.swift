import Foundation

/// Watches CPU load (1-minute load average, normalized per core).
public struct CPUMonitor: Monitor {
    public let id = "cpu"
    public let label = "CPU"
    public let icon = "⚙️"
    public init() {}

    public func sample() -> Reading {
        var loads = [Double](repeating: 0, count: 3)
        getloadavg(&loads, 3)
        let cores = Double(max(1, ProcessInfo.processInfo.activeProcessorCount))
        let perCore = min(1.0, loads[0] / cores)
        return Reading(mood: .fromHealth(1 - perCore),                  // less load = healthier
                       value: String(format: "%.0f%%", perCore * 100),    // templates may add "load"
                       display: String(format: "%.0f%% load", perCore * 100))
    }
}
