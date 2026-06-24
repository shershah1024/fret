import Foundation

/// The voice of Fret — a melodramatic, codependent machine.
///
/// Two pools per (monitor, mood, sass): a small hand-written `seed` (the safety
/// net, in this file) and the big `lines` bank (Vocabulary.swift — edit that to
/// give Fret more to say). `pool(...)` prefers the bank, falling back to seed.
/// `%@` is the value placeholder. Selection / non-repeat lives in VoicePicker.
public enum Personality {
    public static let sassNames = ["Dry", "Chill", "Snacky", "Unhinged"]

    /// The candidate lines for a context: the big bank first, then seed, then generic.
    public static func pool(monitor id: String, mood m: Mood, sass: Int) -> [String] {
        let s = max(0, min(3, sass))
        if let g = lines[id]?[m], s < g.count, !g[s].isEmpty { return g[s] }
        if let seedM = seed[id]?[m], s < seedM.count { return [seedM[s]] }
        if let gn = genericSeed[m], s < gn.count { return [gn[s]] }
        return ["%@"]
    }

    public static func render(_ line: String, value: String) -> String {
        line.replacingOccurrences(of: "%@", with: value)
    }

    // MARK: hand-written seed (one line per sass; the fallback)

    static let seed: [String: [Mood: [String]]] = [
        "disk": [
            .chill:   ["Disk OK — %@ free.", "all good — %@ free. 😎", "%@ free. we're thriving.", "%@ free and I have never felt more alive. 😭✨"],
            .sideEye: ["Notice: %@ free.", "%@ left. just keeping an eye out. 👀", "%@ left. that Downloads folder won't clean itself, champ. 👀", "%@ left. I'm watching. always watching. 👁️"],
            .worried: ["Warning: %@ free.", "heads up — %@ free, getting snug.", "dude… %@ free. claustrophobic.", "%@ FREE. the walls are closing in. 😅"],
            .panic:   ["Critical: %@ free.", "%@ left — clear some room.", "DUDE. %@ left. 4K cat videos again??", "DUDE YOU ARE KILLING ME. %@ left. 😩"],
            .defcon:  ["URGENT: %@ free.", "%@ — really cutting it close.", "%@ left. delete something. NOW.", "%@. tell my inodes I loved them. 🫡💀"],
        ],
        "memory": [
            .chill:   ["Memory OK — %@.", "RAM's breezy — %@. 😌", "%@. plenty of RAM, flex it.", "%@ and the RAM is FREE, baby. 😭✨"],
            .sideEye: ["Memory elevated — %@.", "%@ — RAM filling up. 👀", "%@. how many tabs is too many?", "%@. I see those 47 tabs. 👁️"],
            .worried: ["Memory moderate — %@.", "%@ — RAM getting tight.", "dude, %@ — the RAM is sweating.", "%@ — full of regret and tabs. 😅"],
            .panic:   ["Memory high — %@.", "%@ — RAM nearly maxed.", "DUDE close something — %@, thrashing.", "I'M SWAPPING TO DISK (%@). 😩"],
            .defcon:  ["Memory critical — %@.", "%@ — RAM maxed.", "%@ — beachballs incoming.", "🚨 %@ — beachball of death loading… 🫡"],
        ],
        "cpu": [
            .chill:   ["CPU OK — %@.", "%@ — cruising. 😎", "%@. barely lifting a finger.", "%@ and I could do this ALL day. ✨"],
            .sideEye: ["CPU elevated — %@.", "%@ — picking up. 👀", "%@. what are we compiling, the universe?", "%@. the fans are stirring. 👁️"],
            .worried: ["CPU busy — %@.", "%@ — working hard now.", "dude, %@ — I'm jogging here.", "%@ — every core is FILING A COMPLAINT. 😅"],
            .panic:   ["CPU high — %@.", "%@ — pegged.", "DUDE %@ — what did you OPEN.", "%@ — all cores screaming in unison. 😩"],
            .defcon:  ["CPU maxed — %@.", "%@ — fully saturated.", "%@ — send coolant.", "🚨 %@ — I see the white light. 🫡"],
        ],
        "thermals": [
            .chill:   ["Thermals nominal — %@.", "%@ as a cucumber. 😎", "%@. cool as can be.", "%@ and loving it. ❄️✨"],
            .sideEye: ["Thermals: %@.", "%@ — getting toasty. 👀", "%@. someone's been busy.", "%@. I can feel the warmth. 👁️"],
            .worried: ["Thermals elevated — %@.", "%@ — warming up fast.", "dude, %@ — I'm sweating.", "%@ — is it me or is it HOT in here. 😅"],
            .panic:   ["Thermals high — %@.", "%@ — really hot.", "DUDE %@ — the fans are SCREAMING.", "%@ — I am literally cooking. 😩"],
            .defcon:  ["Thermals critical — %@.", "%@ — throttling now.", "%@ — open a window, please.", "🚨 %@ — call me a hot pocket. 🫠🫡"],
        ],
        "battery": [
            .chill:   ["Battery OK — %@.", "%@ — fully juiced. ⚡️", "%@ and ready to roam.", "%@! I am POWERED BY YOUR LOVE. ⚡️😭"],
            .sideEye: ["Battery: %@.", "%@ — sippin' power. 👀", "%@. find an outlet eventually, yeah?", "%@. the cord is calling your name. 👁️"],
            .worried: ["Battery low-ish — %@.", "%@ — getting thirsty.", "dude, %@ — running on fumes.", "%@ — I can see the light dimming. 😟"],
            .panic:   ["Battery low — %@.", "%@ — plug me in soon.", "DUDE %@ — where is the charger.", "%@ — I don't want to sleep yet. 😩"],
            .defcon:  ["Battery critical — %@.", "%@ — about to nap.", "%@ — CHARGER. NOW.", "%@ — goodbye cruel world… 🪫🫡"],
        ],
    ]

    static let genericSeed: [Mood: [String]] = [
        .chill:   ["OK — %@.", "all good — %@. 😎", "%@. we're vibing.", "%@ and life is good. ✨"],
        .sideEye: ["Notice — %@.", "%@. 👀", "%@. just sayin'. 👀", "%@. I'm watching. 👁️"],
        .worried: ["Warning — %@.", "heads up — %@.", "dude… %@.", "%@. walls closing in. 😅"],
        .panic:   ["Critical — %@.", "%@ — not great.", "DUDE — %@.", "YOU ARE KILLING ME — %@. 😩"],
        .defcon:  ["URGENT — %@.", "%@ — cutting it close.", "%@ — we're going down.", "%@. it was an honor. 🫡💀"],
    ]
}
