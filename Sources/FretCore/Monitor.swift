import Foundation

/// How a vital feels right now, derived from a 0…1 health fraction (1 = great,
/// 0 = terrible). Notification policy lives on the quartiles: only the top 25%
/// (chill → happy) and the bottom 25% (panic/defcon → nag) speak up; the middle
/// 50% (side-eye / worried) stays silent.
public enum Mood: Int, CaseIterable, Sendable {
    case defcon, panic, worried, sideEye, chill   // raw 0…4, worst → best

    /// h: 1 = perfectly healthy, 0 = critical.
    public static func fromHealth(_ h: Double) -> Mood {
        switch h {
        case 0.75...:      return .chill      // top 25%   → good news
        case 0.50..<0.75:  return .sideEye    // ┐ middle 50%
        case 0.25..<0.50:  return .worried    // ┘ silent
        case 0.125..<0.25: return .panic      // ┐ bottom 25%
        default:           return .defcon     // ┘ nag
        }
    }

    public var isBad: Bool  { self == .panic || self == .defcon }   // bottom 25%
    public var isGood: Bool { self == .chill }                      // top 25%

    /// A feeling face — deliberately NOT a device glyph (the monitor's own icon
    /// says *what* it is; this says *how it feels*).
    public var face: String {
        switch self {
        case .chill:   return "😌"
        case .sideEye: return "🙂"
        case .worried: return "😟"
        case .panic:   return "😩"
        case .defcon:  return "🆘"
        }
    }
}

/// One sample of a vital.
public struct Reading: Sendable {
    public let mood: Mood
    public let value: String     // bare, for personality templating: "13.2", "78%"
    public let display: String   // full, for the menu bar: "13.2 GB free", "78% used"
    public init(mood: Mood, value: String, display: String? = nil) {
        self.mood = mood; self.value = value; self.display = display ?? value
    }
}

/// A pluggable system-pressure monitor. Add RAM, CPU, thermals, battery… by
/// conforming a new type and dropping it into the Engine's monitor list.
public protocol Monitor: Sendable {
    var id: String { get }       // stable key, e.g. "disk", "memory"
    var label: String { get }    // human label, e.g. "Disk", "Memory"
    var icon: String { get }     // distinct per-vital glyph, e.g. "💽", "🧠"
    func sample() -> Reading
}
