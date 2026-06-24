# Fret 🫠

**Your Mac's tiny, anxious best friend.** A little menu-bar creature that watches
your machine's vitals — disk, memory, CPU, heat, battery — and only speaks up when
it actually matters, with escalating drama and the occasional 🎉.

**→ [fret.tslfiles.org](https://fret.tslfiles.org)** for the download.

```
💾 → 👀 → 😅 → 😩 → 🆘     chill · side-eye · worried · panic · defcon
```
> "2.1 GB left. one more screenshot and we both go down. delete something. NOW."

## Why this exists

I built Fret because my **8 GB Mac kept dying.** Running machine-learning
workloads on it, I'd hit out-of-memory crashes **at least three times a day** —
usually right after the disk had quietly filled up or RAM had redlined with zero
warning. I wanted something that would just *tell me* before it all fell over —
with enough personality that I wouldn't resent the interruption. So: a small
creature that frets about my machine's vitals so I don't have to.

## What it does

- Watches five vitals: **disk, memory, CPU, thermals, battery.**
- **Only notifies at the extremes** — it nags when something's genuinely wrong and
  cheers 🎉 when a vital recovers. The comfortable middle is silent. No noise.
- **At most two nags** per spell, then it lets it go. It frets; it doesn't harass.
- A **sass dial** (Dry → Chill → Snacky → Unhinged) sets how much attitude you get.
- Fully **on-device.** No network, no account, no telemetry — nothing leaves your Mac.
  (It's a menu-bar daemon watching your system; you should be able to read every line.)

## Install

Download the notarized app from **[fret.tslfiles.org](https://fret.tslfiles.org)**,
drag it to Applications, done. macOS 13+, Apple Silicon.

Or build it yourself:

```bash
swift build -c release --product fret        # the CLI / daemon
.build/release/fret --once --sass 3          # try it in the terminal

scripts/build_app.sh                         # assemble Fret.app (ad-hoc signed)
scripts/build_app.sh --notarize --install    # if you have a Developer ID cert
scripts/install_agent.sh                     # run the CLI as a login LaunchAgent
```

## Add your own lines ✍️

This is the fun part. Fret's whole vocabulary lives in one file:
**[`Sources/FretCore/Vocabulary.swift`](Sources/FretCore/Vocabulary.swift)**, shaped
as `[monitor: [mood: [sass0, sass1, sass2, sass3]]]`. Each entry is just a list of
interchangeable one-liners.

Want Fret to say more? **Add lines to any list.** The only rules:

- include `%@` exactly once (it's the live value — `12.3 GB`, `78%`, `warm`),
- keep it short (it shows up in a notification banner),
- match the mood and pick the right sass slot.

Fret plays every line in a pool once (in random order) before repeating, so more
lines = it feels endless. **PRs with new lines very welcome.** 🫶 Adding a whole new
vital (say, network or fan RPM) is a small `Monitor` conformer in `Sources/FretCore/`.

## How it's built

- `FretCore` — the brains: `Monitor` protocol (Disk/Memory/CPU/Thermal/Battery),
  the `Engine` (when to speak), `Personality` + `Vocabulary` (what to say),
  `VoicePicker` (non-repeating selection). Dependency-free.
- `fret` — the CLI / launchd daemon.
- `FretApp` — the SwiftUI `MenuBarExtra` app (notifications, sass dial, launch-at-login).

## License

MIT — see [LICENSE](LICENSE). Take it, fork it, make it weirder.
