import Foundation

/// Non-repeating line chooser: a shuffle-bag per (monitor|mood|sass) key. Returns
/// every line in a pool once (in random order) before any repeats — so it feels
/// limitless until the pool is genuinely exhausted, then reshuffles.
public final class VoicePicker {
    private var bags: [String: [Int]] = [:]

    public init() {}

    public func nextIndex(key: String, count: Int) -> Int {
        guard count > 1 else { return 0 }
        if (bags[key]?.isEmpty ?? true) { bags[key] = Array(0..<count).shuffled() }
        return bags[key]!.removeLast()
    }
}
