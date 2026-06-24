// FretApp — the menu-bar face of Fret. A SwiftUI MenuBarExtra that shows
// your machine's worst mood as a glyph, lists each vital, lets you turn the sass
// dial, posts BRANDED notifications via UNUserNotificationCenter, and can launch
// at login. No dock icon (LSUIElement).

import SwiftUI
import UserNotifications
import ServiceManagement
import FretCore

// MARK: - Watcher (samples on a timer, publishes state, fires notifications)

@MainActor
final class Watcher: ObservableObject {
    static let shared = Watcher()

    @Published var readings: [(icon: String, label: String, value: String, mood: Mood)] = []
    @Published var glyph: String = "😌"   // menu-bar: worst monitor's icon, or a content face
    @AppStorage("sass") var sass: Int = 2 { didSet { engine.sass = sass; tick() } }
    @AppStorage("intervalSeconds") var intervalSeconds: Int = 60 { didSet { restart() } }

    private let engine = Engine(monitors: [DiskMonitor(), MemoryMonitor(), CPUMonitor(), ThermalMonitor(), BatteryMonitor()])
    private var timer: Timer?

    func start() {
        engine.sass = sass
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
        restart()
    }

    private func restart() {
        timer?.invalidate()
        tick()
        timer = Timer.scheduledTimer(withTimeInterval: Double(max(5, intervalSeconds)), repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
    }

    func tick() {
        for e in engine.tick() where e.banner {
            notify(icon: e.icon, label: e.good ? "\(e.label) 🎉" : e.label, body: e.message)
        }
        readings = engine.monitors.map { m in let r = m.sample(); return (m.icon, m.label, r.display, r.mood) }
        let w = engine.worst()
        glyph = w.mood.isBad ? w.icon : "😌"     // show WHICH vital is alarming; else content
    }

    private func notify(icon: String, label: String, body: String) {
        let c = UNMutableNotificationContent()
        c.title = "Fret \(icon) \(label)"; c.body = body
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: UUID().uuidString, content: c, trigger: nil))
    }

    /// Fire a sample notification on demand (menu → Test notification).
    func testPing() {
        notify(icon: "😌", label: "Hello", body: "it's me, Fret. if you can see my face here, we're good. 🫶")
    }
}

// MARK: - Login item (launch at login via SMAppService)

enum LoginItem {
    static var enabled: Bool { SMAppService.mainApp.status == .enabled }
    static func toggle() {
        do { try (enabled ? SMAppService.mainApp.unregister() : SMAppService.mainApp.register()) }
        catch { NSLog("Fret login-item toggle failed: \(error)") }
    }
}

// MARK: - App lifecycle

final class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    func applicationDidFinishLaunching(_ n: Notification) {
        UNUserNotificationCenter.current().delegate = self
        Task { @MainActor in Watcher.shared.start() }
    }
    // Show banners even while the (background) app is frontmost-less but active.
    func userNotificationCenter(_ c: UNUserNotificationCenter, willPresent n: UNNotification,
                                withCompletionHandler h: @escaping (UNNotificationPresentationOptions) -> Void) {
        h([.banner, .sound])
    }
}

// MARK: - Scene

@main
struct FretApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @ObservedObject private var watcher = Watcher.shared

    var body: some Scene {
        MenuBarExtra {
            ForEach(Array(watcher.readings.enumerated()), id: \.offset) { _, r in
                Text("\(r.icon) \(r.label) — \(r.value)  \(r.mood.face)")
            }
            Divider()
            Picker("Sass", selection: $watcher.sass) {
                ForEach(0..<Personality.sassNames.count, id: \.self) { Text(Personality.sassNames[$0]).tag($0) }
            }
            Picker("Check every", selection: $watcher.intervalSeconds) {
                Text("30s").tag(30); Text("1 min").tag(60); Text("5 min").tag(300)
            }
            Divider()
            Button("Test notification 🔔") { watcher.testPing() }
            Button(LoginItem.enabled ? "✓ Launch at Login" : "Launch at Login") { LoginItem.toggle() }
            Button("Quit Fret") { NSApplication.shared.terminate(nil) }
        } label: {
            Text(watcher.glyph)
        }
        .menuBarExtraStyle(.menu)
    }
}
