import Foundation
import Combine

final class Session: ObservableObject {
    enum Stage { case running, safety, journal }

    @Published private(set) var stage: Stage = .running
    @Published private(set) var index = 0
    @Published private(set) var elapsed: Double = 0      // within current phase
    @Published private(set) var paused = false
    @Published private(set) var caption = ""
    @Published private(set) var pacerStep: PacerStep?
    @Published private(set) var pacerProgress: Double = 0 // 0...1 within current step
    @Published private(set) var safetyElapsed: Double = 0

    var phases: [Phase]
    let badDay: Bool
    let store: Store
    let audio = AudioEngine.shared

    private var timer: Timer?
    private var lastTick = Date()
    private var totalActive: Double = 0
    private var fired = Set<Int>()
    private var bellRung = false
    private var pacerStart: Double?
    private var lastStepIndex = -1
    private var activity: NSObjectProtocol?
    var onFinish: (() -> Void)?

    /// Dev aid: SADHANA_SPEED=20 runs the session 20x faster.
    static let speed = Double(ProcessInfo.processInfo.environment["SADHANA_SPEED"] ?? "") ?? 1

    var phase: Phase { phases[index] }
    var overtime: Bool { elapsed >= phase.duration }
    var remaining: Double { max(0, phase.duration - elapsed) }
    var minutesPracticed: Double { totalActive / 60 }

    let guidedURL: URL?

    init(store: Store, badDay: Bool) {
        self.store = store
        self.badDay = badDay
        self.guidedURL = nil
        self.phases = badDay ? Plan.badDay() : Plan.full(ratio: store.effectiveRatio)
    }

    /// Logging a session done elsewhere (e.g. in the Medito app): straight to the diary.
    init(store: Store, externalMinutes: Double) {
        self.store = store
        self.badDay = false
        self.guidedURL = nil
        self.phases = Plan.guided(title: "Medito", duration: externalMinutes * 60)
        self.totalActive = externalMinutes * 60
        self.stage = .journal
    }

    /// A guided-audio day: plays the chosen recording start to end.
    init(store: Store, guided url: URL) {
        self.store = store
        self.badDay = false
        self.guidedURL = url
        let title = url.deletingPathExtension().lastPathComponent
        self.phases = Plan.guided(title: title, duration: 20 * 60)
    }

    func start() {
        activity = ProcessInfo.processInfo.beginActivity(
            options: [.idleDisplaySleepDisabled, .userInitiated], reason: "Sadhana")
        audio.voiceVolume = Float(store.voiceVolume)
        audio.onVoiceIdle = { [weak self] in self?.voiceIdle() }
        if let url = guidedURL {
            let d = audio.playGuided(url)
            if d > 0 { phases[0] = Plan.guided(title: phases[0].title, duration: d)[0] }
        }
        beginPhase(0)
        lastTick = Date()
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in self?.tick() }
        RunLoop.main.add(timer!, forMode: .common)
    }

    func teardown() {
        timer?.invalidate(); timer = nil
        audio.stopVoice()
        audio.stopGuided()
        audio.onVoiceIdle = nil
        if let a = activity { ProcessInfo.processInfo.endActivity(a); activity = nil }
    }

    private func beginPhase(_ i: Int, bell: Bool = true) {
        index = i
        elapsed = 0
        fired = []
        bellRung = false
        pacerStart = nil
        pacerStep = nil
        lastStepIndex = -1
        caption = ""
        if bell && phases[i].kind != .close && phases[i].kind != .guided { audio.bell() }
        if Session.speed != 1 { NSLog("phase %d %@", i, phases[i].title) }
        fireCues()
    }

    private func tick() {
        let now = Date()
        let dt = now.timeIntervalSince(lastTick) * Session.speed
        lastTick = now
        if paused { return }
        if stage == .safety { safetyElapsed += dt; return }
        guard stage == .running else { return }
        elapsed += dt
        totalActive += dt
        fireCues()
        updatePacer()

        if elapsed >= phase.duration && !bellRung {
            bellRung = true
            if phase.kind == .close || phase.kind == .guided {
                finish()
                return
            }
            // In "wait for me" mode the bell marks time-up; the next step then starts without another.
            if store.waitForMe { audio.bell() }
            if !store.waitForMe {
                let i = index
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
                    guard let self, self.index == i, self.stage == .running else { return }
                    self.next()
                }
            }
        }
    }

    private func fireCues() {
        for (i, c) in phase.cues.enumerated() where !fired.contains(i) && elapsed >= c.at {
            fired.insert(i)
            switch c.cue {
            case .voice(let k): audio.say(k)
            case .text(let t): caption = t
            }
        }
        if phase.kind == .sankalpa && caption.isEmpty { caption = store.sankalpa }
        if phase.kind == .nadi && pacerStart == nil && elapsed > 60 { pacerStart = elapsed }
    }

    private func voiceIdle() {
        if stage == .running, phase.kind == .nadi, pacerStart == nil, elapsed > 1 {
            pacerStart = elapsed + 1.5
        }
    }

    private func updatePacer() {
        guard phase.kind == .nadi, let ps = pacerStart, elapsed >= ps else { return }
        let (inh, exh) = phase.ratio.counts
        let cycle = 2 * (inh + exh)
        let t = elapsed - ps
        let round = Int(t / cycle)
        var within = t.truncatingRemainder(dividingBy: cycle)
        var step = 0
        let lens = [inh, exh, inh, exh]
        while within >= lens[step] { within -= lens[step]; step += 1 }
        pacerProgress = within / lens[step]
        let global = round * 4 + step
        if global != lastStepIndex {
            lastStepIndex = global
            let s = PacerStep.round[step]
            pacerStep = s
            caption = s.label
            if round < phase.pacerVoiceRounds {
                audio.say(s.voiceKey)
            } else if round == phase.pacerVoiceRounds && step == 0 {
                audio.say("p_own")
            }
        }
    }

    /// Dev aid for snapshot rendering.
    func debugJump(to i: Int, elapsed e: Double) {
        beginPhase(i)
        elapsed = e
        fireCues()
        if phase.kind == .nadi { pacerStart = 0; updatePacer() }
    }

    // MARK: Controls

    func next() {
        guard stage == .running else { return }
        audio.stopVoice()
        if index + 1 >= phases.count { finish(); return }
        beginPhase(index + 1, bell: !(bellRung && store.waitForMe))
    }

    func togglePause() {
        paused.toggle()
        if paused { audio.pauseAll() } else { audio.resumeAll() }
    }

    func stopForSafety() {
        guard stage == .running else { return }
        if paused { togglePause() }
        stage = .safety
        safetyElapsed = 0
        audio.sayNow("stop")
    }

    func restartGently() {
        phases[index].ratio = .r33
        phases[index].pacerVoiceRounds = 1
        stage = .running
        lastStepIndex = -1
        audio.say("bd2")
        pacerStart = elapsed + 9
    }

    func skipAfterSafety() {
        stage = .running
        next()
    }

    func finish() {
        guard stage != .journal else { return }
        timer?.invalidate(); timer = nil
        audio.stopGuided()
        if phase.kind != .close { audio.stopVoice() }
        if let a = activity { ProcessInfo.processInfo.endActivity(a); activity = nil }
        stage = .journal
        if Session.speed != 1 { NSLog("journal %d min", Int(minutesPracticed)) }
        if badDay { audio.say("bd_end") }
    }
}
