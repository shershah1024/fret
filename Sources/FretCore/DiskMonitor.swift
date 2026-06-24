import Foundation

/// Watches free space on a volume (default: home), by ABSOLUTE GB free — a near-
/// full disk is bad regardless of total size. Bad (nag) under ~10 GB; happy
/// (celebrate) over ~50 GB; silent in between.
public struct DiskMonitor: Monitor {
    public let id = "disk"
    public let label = "Disk"
    public let icon = "💽"
    public let path: String

    public init(path: String = NSHomeDirectory()) { self.path = path }

    public func sample() -> Reading {
        let free = Self.freeBytes(path)
        guard free >= 0 else { return Reading(mood: .chill, value: "?") }
        let gb = Double(free) / 1_073_741_824
        let mood: Mood
        switch gb {
        case ..<5:   mood = .defcon    // ┐ bottom 25% → nag
        case ..<10:  mood = .panic     // ┘
        case ..<25:  mood = .worried   // ┐ middle 50% → silent
        case ..<50:  mood = .sideEye   // ┘
        default:     mood = .chill     //   top → happy
        }
        return Reading(mood: mood,
                       value: String(format: "%.1f GB", gb),          // templates add "free"/"left"
                       display: String(format: "%.1f GB free", gb))
    }

    private static func freeBytes(_ path: String) -> Int64 {
        let url = URL(fileURLWithPath: path)
        if let v = try? url.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey]),
           let b = v.volumeAvailableCapacityForImportantUsage { return b }
        if let a = try? FileManager.default.attributesOfFileSystem(forPath: path),
           let f = (a[.systemFreeSize] as? NSNumber)?.int64Value { return f }
        return -1
    }
}
