import Foundation

enum Ratio: String, CaseIterable, Codable, Identifiable {
    case auto, r33, r44, r48
    var id: String { rawValue }
    var label: String {
        switch self {
        case .auto: return "Apne aap (hafte ke hisaab se)"
        case .r33: return "3 : 3"
        case .r44: return "4 : 4"
        case .r48: return "4 : 8"
        }
    }
    var counts: (inhale: Double, exhale: Double) {
        switch self {
        case .r33: return (3, 3)
        case .r48: return (4, 8)
        default: return (4, 4)
        }
    }
    var voiceKey: String {
        switch self {
        case .r33: return "s2b_33"
        case .r48: return "s2b_48"
        default: return "s2b_44"
        }
    }
}

enum Cue {
    case voice(String)
    case text(String)
}

struct TimedCue {
    let at: Double
    let cue: Cue
}

enum PhaseKind { case settle, nadi, bhramari, witness, visualize, sankalpa, close, guided }

struct Phase: Identifiable {
    let id = UUID()
    let kind: PhaseKind
    let title: String
    let subtitle: String
    let duration: Double
    let cues: [TimedCue]
    var ratio: Ratio = .r44
    var pacerVoiceRounds = 2
}

enum Plan {
    static func full(ratio: Ratio) -> [Phase] {
        [
            Phase(kind: .settle, title: "Baithna", subtitle: "Bas pahuncho", duration: 120, cues: [
                .init(at: 0, cue: .voice("s1a")),
                .init(at: 0, cue: .text("Aankhein band. Kuch karna nahi hai.")),
                .init(at: 22, cue: .voice("s1b")),
                .init(at: 22, cue: .text("5 saans · har saans pe ek jagah dheeli")),
                .init(at: 35, cue: .voice("s1_1")), .init(at: 35, cue: .text("Maatha")),
                .init(at: 45, cue: .voice("s1_2")), .init(at: 45, cue: .text("Jabda")),
                .init(at: 55, cue: .voice("s1_3")), .init(at: 55, cue: .text("Kandhe")),
                .init(at: 65, cue: .voice("s1_4")), .init(at: 65, cue: .text("Pet")),
                .init(at: 75, cue: .voice("s1_5")), .init(at: 75, cue: .text("Haath")),
                .init(at: 84, cue: .voice("s1c")),
                .init(at: 84, cue: .text("Saans ko sirf dekho. Andar thandak, bahar garmi.")),
            ]),
            Phase(kind: .nadi, title: "Nadi Shodhana", subtitle: "Sadhana ka dil", duration: 600, cues: [
                .init(at: 0, cue: .voice("s2a")),
                .init(at: 0, cue: .text("Vishnu mudra · angootha daayein, anamika baayein")),
                .init(at: 0, cue: .voice(ratio.voiceKey)),
                .init(at: 150, cue: .voice("r1")),
                .init(at: 270, cue: .voice("r2")),
                .init(at: 390, cue: .voice("r3")),
                .init(at: 510, cue: .voice("r4")),
            ], ratio: ratio),
            Phase(kind: .bhramari, title: "Bhramari", subtitle: "Bhanwre ki goonj", duration: 145, cues: [
                .init(at: 0, cue: .voice("s3a")),
                .init(at: 0, cue: .text("Haath neeche. Ek-do normal saans.")),
                .init(at: 9, cue: .voice("s3b")),
                .init(at: 9, cue: .text("Kaan band · lambi saans · halki \"mmmm\" · 5 baar")),
                .init(at: 102, cue: .voice("s3c")),
                .init(at: 102, cue: .text("Bas is khamoshi ko suno.")),
            ]),
            Phase(kind: .witness, title: "Saakshi", subtitle: "Pehchaano aur chhodo", duration: 300, cues: [
                .init(at: 0, cue: .voice("s4a")),
                .init(at: 0, cue: .text("Saans apne aap chal rahi hai.")),
                .init(at: 16, cue: .voice("s4b")),
                .init(at: 16, cue: .text("Naam do · pakdo mat · wapas saans pe")),
                .init(at: 130, cue: .voice("q")),
                .init(at: 130, cue: .text("Ise kaun dekh raha hai?")),
                .init(at: 160, cue: .text("Har wapsi ek rep hai.")),
                .init(at: 220, cue: .voice("q")),
                .init(at: 220, cue: .text("Ise kaun dekh raha hai?")),
                .init(at: 250, cue: .text("Naam do · pakdo mat · wapas saans pe")),
            ]),
            Phase(kind: .visualize, title: "Kalpana", subtitle: "Roshni aur aaj ka din", duration: 180, cues: [
                .init(at: 0, cue: .voice("v1")),
                .init(at: 0, cue: .text("Dil ke beech ek garam, sunehri roshni")),
                .init(at: 24, cue: .voice("v2")),
                .init(at: 24, cue: .text("Har saans pe roshni phailti hai")),
                .init(at: 70, cue: .voice("v3")),
                .init(at: 70, cue: .text("Aaj ka din · subah se")),
                .init(at: 98, cue: .voice("v4")),
                .init(at: 98, cue: .text("Mushkil pal · jawab se pehle ek saans")),
                .init(at: 132, cue: .voice("v5")),
                .init(at: 132, cue: .text("Raat · mic · pair zameen pe")),
                .init(at: 165, cue: .voice("v6")),
                .init(at: 165, cue: .text("Bas wo roshni")),
            ]),
            Phase(kind: .sankalpa, title: "Sankalpa", subtitle: "Teen baar, mann mein", duration: 60, cues: [
                .init(at: 0, cue: .voice("s5a")),
            ]),
            closing(),
        ]
    }

    static func badDay() -> [Phase] {
        [
            Phase(kind: .settle, title: "Baithna", subtitle: "Bura din · 3 minute", duration: 60, cues: [
                .init(at: 0, cue: .voice("bd1")),
                .init(at: 0, cue: .text("Baitho. 5 saans.")),
            ]),
            Phase(kind: .nadi, title: "Nadi Shodhana", subtitle: "3 : 3", duration: 60, cues: [
                .init(at: 0, cue: .voice("bd2")),
            ], ratio: .r33, pacerVoiceRounds: 1),
            Phase(kind: .bhramari, title: "Bhramari", subtitle: "3 rounds", duration: 70, cues: [
                .init(at: 0, cue: .voice("bd3")),
                .init(at: 0, cue: .text("Kaan band · lambi saans · halki \"mmmm\" · 3 baar")),
            ]),
            closing(),
        ]
    }

    static func guided(title: String, duration: Double) -> [Phase] {
        [Phase(kind: .guided, title: title, subtitle: "Guided din", duration: duration, cues: [])]
    }

    static func closing() -> Phase {
        Phase(kind: .close, title: "Band karna", subtitle: "", duration: 38, cues: [
            .init(at: 0, cue: .voice("c1")),
            .init(at: 0, cue: .text("Hathelian ragdo, jab tak garam na ho jaayein")),
            .init(at: 11, cue: .voice("c2")),
            .init(at: 11, cue: .text("Garam hathelian aankhon pe · 3 saans")),
            .init(at: 22, cue: .voice("c3")),
            .init(at: 22, cue: .text("Dheere se aankhein kholo")),
        ])
    }
}

enum Nostril { case left, right }

struct PacerStep {
    let inhale: Bool
    let side: Nostril
    var voiceKey: String {
        switch (inhale, side) {
        case (true, .left): return "p_inL"
        case (false, .right): return "p_outR"
        case (true, .right): return "p_inR"
        case (false, .left): return "p_outL"
        }
    }
    var label: String {
        (side == .left ? "Baayein" : "Daayein") + (inhale ? " se andar" : " se bahar")
    }
    static let round: [PacerStep] = [
        .init(inhale: true, side: .left), .init(inhale: false, side: .right),
        .init(inhale: true, side: .right), .init(inhale: false, side: .left),
    ]
}
