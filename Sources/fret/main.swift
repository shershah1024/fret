// fret — CLI / launchd daemon. Samples disk + memory and nags via stdout and
// (with --notify) macOS banners. The menu-bar app (FretApp) is the friendlier
// face of the same FretCore engine.
//
//   fret --once --sass 3              # one-shot, unhinged
//   fret --interval 30 --notify       # run forever, banners on
//   fret --disk-path /                 # watch a specific volume
//
// Flags: --interval <s> (default 60), --once, --notify, --sass <0-3>, --disk-path <p>.

import Foundation
import FretCore

let argv = CommandLine.arguments
func flag(_ n: String) -> Bool { argv.contains(n) }
func opt(_ n: String) -> String? { argv.firstIndex(of: n).flatMap { $0 + 1 < argv.count ? argv[$0 + 1] : nil } }

let interval = Double(opt("--interval") ?? "") ?? 60
let once     = flag("--once")
let notify   = flag("--notify")
let sass     = max(0, min(3, Int(opt("--sass") ?? "") ?? 2))
let diskPath = opt("--disk-path") ?? NSHomeDirectory()

// --selftest: drive a scripted mood sequence to prove worsen + recovery surfacing.
if flag("--selftest") {
    final class Fake: Monitor, @unchecked Sendable {
        let id = "disk"; let label = "Disk"; let icon = "💽"; var seq: [Mood]; var i = 0
        init(_ s: [Mood]) { seq = s }
        func sample() -> Reading { let m = seq[min(i, seq.count - 1)]; i += 1; return Reading(mood: m, value: "demo") }
    }
    let seq: [Mood] = [.chill, .sideEye, .worried, .panic, .defcon, .panic, .worried, .sideEye, .chill]
    let e = Engine(monitors: [Fake(seq)], sass: sass, reNagInterval: 0)
    for step in seq {
        for ev in e.tick() {
            print("\(String(describing: step).padding(toLength: 8, withPad: " ", startingAt: 0)) \(ev.good ? "🎉 GOOD " : ev.banner ? "🔔 nag  " : "·· log  ")\(ev.message)")
        }
    }
    print("--- 2-nag cap: stuck in defcon for 5 ticks (reNag=0) ---")
    let stuck = Engine(monitors: [Fake([.defcon])], sass: sass, reNagInterval: 0)
    for t in 1...5 {
        let n = stuck.tick().filter { $0.banner }.count
        print("tick \(t): \(n) nag(s)")
    }
    exit(0)
}

let engine = Engine(monitors: [DiskMonitor(path: diskPath), MemoryMonitor(), CPUMonitor(), ThermalMonitor(), BatteryMonitor()], sass: sass)

func banner(_ icon: String, _ label: String, _ msg: String) {
    guard notify else { return }
    let p = Process(); p.launchPath = "/usr/bin/osascript"
    let safe = msg.replacingOccurrences(of: "\"", with: "'")
    p.arguments = ["-e", "display notification \"\(safe)\" with title \"Fret \(icon) \(label)\""]
    try? p.run()
}

func emit(_ events: [Engine.Event]) {
    for e in events {
        print("[fret] \(e.icon) \(e.good ? "🎉 " : "")\(e.label): \(e.message)"); fflush(stdout)
        if e.banner { banner(e.icon, e.label, e.message) }
    }
}

if once { emit(engine.tick(force: true)); exit(0) }

FileHandle.standardError.write(Data("fret: watching disk+memory every \(interval)s — sass \(sass)\n".utf8))
while true {
    emit(engine.tick())
    Thread.sleep(forTimeInterval: interval)
}
