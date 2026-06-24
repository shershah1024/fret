import Foundation

/// Watches thermal pressure via `ProcessInfo.thermalState` — the cleanest
/// on-device thermal signal macOS exposes.
public struct ThermalMonitor: Monitor {
    public let id = "thermals"
    public let label = "Thermals"
    public let icon = "🌡️"
    public init() {}

    public func sample() -> Reading {
        let h: Double, word: String
        switch ProcessInfo.processInfo.thermalState {
        case .nominal:  (h, word) = (1.0, "cool")      // chill  → good
        case .fair:     (h, word) = (0.6, "warm")      // sideEye → silent
        case .serious:  (h, word) = (0.2, "hot")       // panic  → nag
        case .critical: (h, word) = (0.0, "critical")  // defcon → nag
        @unknown default: (h, word) = (1.0, "cool")
        }
        return Reading(mood: .fromHealth(h), value: word, display: "running \(word)")
    }
}
