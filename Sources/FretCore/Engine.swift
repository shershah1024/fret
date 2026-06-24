import Foundation

/// Samples every monitor each `tick` and decides when to speak up. Policy:
///   • only the EXTREMES notify — bottom 25% (panic/defcon → nag) and a recovery
///     into the top 25% (chill → happy). The middle 50% stays silent.
///   • at most 2 notifications per visit to a state: the first on entry, a second
///     after `reNagInterval` if still stuck — then quiet until the mood changes.
/// Lines are chosen non-repeatingly via VoicePicker. Platform-agnostic.
public final class Engine {
    public struct Event: Sendable {
        public let monitorId: String
        public let label: String
        public let icon: String
        public let reading: Reading
        public let message: String
        public let banner: Bool     // true → surface a notification, not just a log line
        public let good: Bool       // true → good news (recovery), not a nag
    }

    public let monitors: [Monitor]
    public var sass: Int
    public var reNagInterval: TimeInterval
    public let maxPerState = 2

    private let picker = VoicePicker()
    private var lastMood: [String: Mood] = [:]
    private var stateCount: [String: Int] = [:]   // notifications emitted in the current state
    private var lastEmit: [String: Date] = [:]

    public init(monitors: [Monitor], sass: Int = 2, reNagInterval: TimeInterval = 300) {
        self.monitors = monitors
        self.sass = sass
        self.reNagInterval = reNagInterval
    }

    /// Sample all monitors. `force` (a one-shot CLI run) emits every monitor for
    /// display, but still only flags banners on the extremes.
    public func tick(now: Date = Date(), force: Bool = false) -> [Event] {
        var events: [Event] = []
        for m in monitors {
            let r = m.sample()
            let prev = lastMood[m.id]
            if r.mood != prev { stateCount[m.id] = 0 }           // new state → fresh budget
            let improved = prev != nil && r.mood.rawValue > prev!.rawValue   // higher raw = healthier

            let wantsBad  = r.mood.isBad
            let wantsGood = r.mood.isGood && improved             // celebrate only on recovery
            let wantNotify = wantsBad || wantsGood

            let count = stateCount[m.id] ?? 0
            let firstInState = count == 0
            let spaced = now.timeIntervalSince(lastEmit[m.id] ?? .distantPast) >= reNagInterval
            let underCap = count < maxPerState
            let emit = force || (wantNotify && underCap && (firstInState || spaced))

            if emit {
                let pool = Personality.pool(monitor: m.id, mood: r.mood, sass: sass)
                let idx = picker.nextIndex(key: "\(m.id)|\(r.mood.rawValue)|\(sass)", count: pool.count)
                let msg = Personality.render(pool[idx], value: r.value)
                events.append(Event(monitorId: m.id, label: m.label, icon: m.icon, reading: r,
                                    message: msg, banner: wantNotify, good: wantsGood))
                if wantNotify { stateCount[m.id] = count + 1; lastEmit[m.id] = now }
            }
            lastMood[m.id] = r.mood
        }
        return events
    }

    /// The most-severe monitor right now (for the single menu-bar glyph).
    public func worst() -> (icon: String, mood: Mood) {
        let w = monitors.map { ($0.icon, $0.sample().mood) }.min(by: { $0.1.rawValue < $1.1.rawValue })
        return w ?? ("😌", .chill)
    }
}
