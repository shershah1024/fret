import Foundation
#if canImport(IOKit)
import IOKit.ps
#endif

/// Watches battery charge + charging state. While plugged in / charging it never
/// nags (it's recovering); on battery it nags when low; fully charged is good news.
/// On a desktop (no battery) it stays permanently chill (silent).
public struct BatteryMonitor: Monitor {
    public let id = "battery"
    public let label = "Battery"
    public let icon = "🔋"
    public init() {}

    public func sample() -> Reading {
        guard let b = Self.read() else {
            return Reading(mood: .chill, value: "AC", display: "on AC power")
        }
        let pct = Int((b.level * 100).rounded())
        let charged = b.level >= 0.98 || b.charged
        let mood: Mood
        if charged {
            mood = .chill                                   // fully charged → 🎉 on recovery
        } else if b.charging || b.plugged {
            mood = b.level >= 0.5 ? .sideEye : .worried     // charging: silent, never nag
        } else {                                            // on battery, discharging
            switch b.level {
            case ..<0.10: mood = .defcon
            case ..<0.20: mood = .panic
            case ..<0.40: mood = .worried
            case ..<0.60: mood = .sideEye
            default:      mood = .chill
            }
        }
        let suffix = charged ? " ⚡️" : (b.charging ? " ⚡️" : "")
        return Reading(mood: mood, value: "\(pct)%", display: "\(pct)%\(suffix)")
    }

    private struct Info { let level: Double; let charging: Bool; let charged: Bool; let plugged: Bool }

    private static func read() -> Info? {
        #if canImport(IOKit)
        guard let snap = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let list = IOPSCopyPowerSourcesList(snap)?.takeRetainedValue() as? [CFTypeRef] else { return nil }
        for ps in list {
            guard let d = IOPSGetPowerSourceDescription(snap, ps)?.takeUnretainedValue() as? [String: Any] else { continue }
            let cur = (d[kIOPSCurrentCapacityKey as String] as? Int) ?? 0
            let max = (d[kIOPSMaxCapacityKey as String] as? Int) ?? 100
            guard max > 0 else { continue }
            let state = (d[kIOPSPowerSourceStateKey as String] as? String) ?? ""
            return Info(level: Double(cur) / Double(max),
                        charging: (d[kIOPSIsChargingKey as String] as? Bool) ?? false,
                        charged: (d[kIOPSIsChargedKey as String] as? Bool) ?? false,
                        plugged: state == (kIOPSACPowerValue as String))
        }
        #endif
        return nil
    }
}
