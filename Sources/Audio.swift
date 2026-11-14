import AVFoundation

/// Guiding voice (bundled clips, queued, with a breathing pause between parts of a line),
/// two real recorded bells, and an optional guided-audio track. Nothing synthesized.
final class AudioEngine: NSObject, AVAudioPlayerDelegate {
    static let shared = AudioEngine()

    // Voice runs through a small engine with a soft room reverb, so it sounds
    // like someone sitting in the room rather than a dry recording.
    private let engine = AVAudioEngine()
    private let voiceNode = AVAudioPlayerNode()
    private let converter = AVAudioMixerNode() // voice clips are 24 kHz mono; reverb needs 44.1 kHz stereo
    private let reverb = AVAudioUnitReverb()
    private var queue: [(url: URL, gapBefore: Double)] = []
    private var pendingGap: DispatchWorkItem?
    private var generation = 0
    private var paused = false
    private(set) var isSpeaking = false
    var onVoiceIdle: (() -> Void)?

    private var bells: [AVAudioPlayer] = []
    private(set) var guided: AVAudioPlayer?

    var voiceVolume: Float = 1.0 { didSet { voiceNode.volume = voiceVolume } }
    static let partGap = 1.4

    private override init() {
        super.init()
        [voiceNode, converter, reverb].forEach { engine.attach($0) }
        reverb.loadFactoryPreset(.mediumRoom)
        reverb.wetDryMix = 14
        let stereo = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)
        engine.connect(voiceNode, to: converter, format: AVAudioFormat(standardFormatWithSampleRate: 24000, channels: 1))
        engine.connect(converter, to: reverb, format: stereo)
        engine.connect(reverb, to: engine.mainMixerNode, format: stereo)
        try? engine.start()
    }

    private func resource(_ name: String, _ ext: String, _ dir: String) -> URL? {
        Bundle.main.url(forResource: name, withExtension: ext, subdirectory: dir)
    }

    // MARK: Voice

    /// Plays `key.mp3`, or `key_1.mp3`, `key_2.mp3`… with a pause between parts.
    func say(_ key: String) {
        let lead = queue.isEmpty && !isSpeaking ? 0 : 0.8
        if let u = resource(key, "mp3", "voice") {
            queue.append((u, lead))
        } else {
            var i = 1
            while let u = resource("\(key)_\(i)", "mp3", "voice") {
                queue.append((u, i == 1 ? lead : Self.partGap))
                i += 1
            }
        }
        if !isSpeaking { playNext() }
    }

    func sayNow(_ key: String) {
        stopVoice()
        say(key)
    }

    func stopVoice() {
        generation += 1
        paused = false
        queue.removeAll()
        pendingGap?.cancel(); pendingGap = nil
        voiceNode.stop()
        isSpeaking = false
    }

    private func playNext() {
        guard !queue.isEmpty else {
            isSpeaking = false
            onVoiceIdle?()
            return
        }
        isSpeaking = true
        let item = queue.removeFirst()
        let gen = generation
        let work = DispatchWorkItem { [weak self] in
            guard let self, gen == self.generation else { return }
            guard let file = try? AVAudioFile(forReading: item.url) else { self.playNext(); return }
            if !self.engine.isRunning { try? self.engine.start() }
            if file.processingFormat != self.voiceNode.outputFormat(forBus: 0) {
                self.engine.disconnectNodeOutput(self.voiceNode)
                self.engine.connect(self.voiceNode, to: self.converter, format: file.processingFormat)
            }
            self.voiceNode.scheduleFile(file, at: nil, completionCallbackType: .dataPlayedBack) { _ in
                DispatchQueue.main.async {
                    guard gen == self.generation else { return }
                    self.playNext()
                }
            }
            self.voiceNode.volume = self.voiceVolume
            if !self.paused { self.voiceNode.play() }
        }
        pendingGap = work
        DispatchQueue.main.asyncAfter(deadline: .now() + item.gapBefore, execute: work)
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async { self.bells.removeAll { $0 === player } }
    }

    // MARK: Bells

    private func ring(_ name: String, volume: Float) {
        guard let u = resource(name, "m4a", "sounds"), let p = try? AVAudioPlayer(contentsOf: u) else { return }
        p.delegate = self
        p.volume = volume
        bells.append(p)
        p.play()
    }

    /// One short bowl strike.
    func bell() { ring("bell", volume: 0.85) }

    // MARK: Guided audio day

    func playGuided(_ url: URL) -> Double {
        guided = try? AVAudioPlayer(contentsOf: url)
        guided?.volume = voiceVolume
        guided?.play()
        return guided?.duration ?? 0
    }

    func stopGuided() { guided?.stop(); guided = nil }

    // MARK: Pause

    func pauseAll() {
        paused = true
        voiceNode.pause()
        guided?.pause()
    }

    func resumeAll() {
        paused = false
        if isSpeaking { voiceNode.play() }
        guided?.play()
    }
}
