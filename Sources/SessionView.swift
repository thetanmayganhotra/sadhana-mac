import SwiftUI
import AppKit

struct SessionView: View {
    @ObservedObject var session: Session
    @EnvironmentObject var store: Store
    let onDone: () -> Void
    @State private var showInfo = UserDefaults.standard.object(forKey: "showInfo") as? Bool ?? true
    @State private var monitor: Any?
    @State private var confirmEnd = false

    var body: some View {
        ZStack {
            switch session.stage {
            case .running: running
            case .safety: SafetyView(session: session)
            case .journal: JournalView(session: session, onDone: close)
            }
        }
        .animation(.easeInOut(duration: 0.6), value: session.stage)
        .onAppear(perform: installKeys)
        .onDisappear {
            if let m = monitor { NSEvent.removeMonitor(m) }
            session.teardown()
        }
        .confirmationDialog("Aaj ki sadhana yahin khatam karein?", isPresented: $confirmEnd) {
            Button("Haan, diary pe chalo") { session.finish() }
            Button("Nahi, jaari rakho", role: .cancel) {}
        }
    }

    private func close() {
        session.teardown()
        onDone()
    }

    private func installKeys() {
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { e in
            guard session.stage != .journal else { return e }
            switch e.keyCode {
            case 49: // space
                if session.stage == .running { session.next() }
                return nil
            case 53: // esc
                if session.stage == .running {
                    if session.phase.kind == .nadi { session.stopForSafety() } else { confirmEnd = true }
                }
                return nil
            case 35: // p
                session.togglePause(); return nil
            case 34: // i
                toggleInfo(); return nil
            default: return e
            }
        }
    }

    private func toggleInfo() {
        withAnimation(.easeInOut(duration: 0.4)) { showInfo.toggle() }
        UserDefaults.standard.set(showInfo, forKey: "showInfo")
    }

    // MARK: Running

    private var running: some View {
        VStack(spacing: 0) {
            StepDots(phases: session.phases, index: session.index)
                .padding(.top, 34)

            HStack(alignment: .center, spacing: 0) {
                VStack(spacing: 0) {
                    VStack(spacing: 6) {
                        Text(session.phase.title)
                            .font(.serif(36))
                            .foregroundStyle(Palette.ink)
                        if !session.phase.subtitle.isEmpty {
                            Text(session.phase.subtitle)
                                .font(.soft(12)).tracking(1.5).textCase(.uppercase)
                                .foregroundStyle(Palette.ink.opacity(0.4))
                        }
                    }
                    .id(session.index)
                    .transition(.opacity)

                    PhaseArt(session: session)
                        .frame(maxWidth: 380, maxHeight: 400)
                        .padding(.vertical, 8)

                    Text(session.caption)
                        .font(.serif(session.phase.kind == .sankalpa ? 24 : 18, .regular))
                        .italic(session.phase.kind == .sankalpa)
                        .foregroundStyle(Palette.ink.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .frame(height: 56)
                        .animation(.easeInOut(duration: 0.5), value: session.caption)
                        .id(session.caption)
                        .transition(.opacity)

                    TimerLine(session: session)
                        .padding(.top, 6)
                }
                .frame(maxWidth: .infinity)

                if showInfo {
                    InfoPanel(kind: session.phase.kind)
                        .frame(width: 300)
                        .padding(.trailing, 28)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            .frame(maxHeight: .infinity)

            controls.padding(.bottom, 24)
        }
    }

    private var controls: some View {
        HStack(spacing: 12) {
            Button(session.paused ? "Jaari rakho" : "Pause") { session.togglePause() }
                .buttonStyle(QuietButton())
            if session.phase.kind == .nadi {
                Button("Ruko  ·  esc") { session.stopForSafety() }
                    .buttonStyle(QuietButton())
            }
            Button(session.index + 1 < session.phases.count ? "Aage  ·  space" : "Khatam") { session.next() }
                .buttonStyle(QuietButton(prominent: session.overtime))
            Spacer().frame(width: 20)
            Button(showInfo ? "Body info chhupao" : "Body mein kya ho raha hai") { toggleInfo() }
                .buttonStyle(.plain).font(.soft(11)).foregroundStyle(Palette.ink.opacity(0.4))
            Button("Band karo") {
                confirmEnd = true
            }
            .buttonStyle(.plain).font(.soft(11)).foregroundStyle(Palette.ink.opacity(0.4))
        }
    }
}

struct StepDots: View {
    let phases: [Phase]
    let index: Int
    var body: some View {
        HStack(spacing: 18) {
            ForEach(Array(phases.enumerated()), id: \.offset) { i, p in
                VStack(spacing: 6) {
                    Capsule()
                        .fill(i < index ? Palette.gold.opacity(0.6) : i == index ? Palette.gold : Palette.ink.opacity(0.12))
                        .frame(width: i == index ? 28 : 14, height: 3)
                    Text(p.title)
                        .font(.soft(10))
                        .foregroundStyle(Palette.ink.opacity(i == index ? 0.7 : 0.28))
                }
            }
        }
        .animation(.easeInOut(duration: 0.6), value: index)
    }
}

struct TimerLine: View {
    @ObservedObject var session: Session
    var body: some View {
        VStack(spacing: 4) {
            if session.overtime && session.phase.kind != .close {
                Text("+" + clock(session.elapsed - session.phase.duration))
                    .font(.system(size: 22, weight: .ultraLight, design: .rounded)).monospacedDigit()
                    .foregroundStyle(Palette.gold.opacity(0.9))
                Text(store.waitForMe ? "Jitna chaho utna · jab tayyar ho, space" : "Aage badh rahe hain…")
                    .font(.soft(11)).foregroundStyle(Palette.ink.opacity(0.45))
            } else {
                Text(clock(session.remaining.rounded(.up)))
                    .font(.system(size: 22, weight: .ultraLight, design: .rounded)).monospacedDigit()
                    .foregroundStyle(Palette.ink.opacity(session.paused ? 0.35 : 0.7))
                Text(session.paused ? "Ruka hua · p" : " ")
                    .font(.soft(11)).foregroundStyle(Palette.ink.opacity(0.45))
            }
        }
    }
    private var store: Store { session.store }
}

struct InfoPanel: View {
    let kind: PhaseKind
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Body mein kya ho raha hai")
                .font(.soft(11, .medium)).tracking(1.2).textCase(.uppercase)
                .foregroundStyle(Palette.gold.opacity(0.8))
                .padding(.bottom, 14)
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(kind.bodyInfo, id: \.title) { item in
                        VStack(alignment: .leading, spacing: 5) {
                            Text(item.title)
                                .font(.serif(15, .regular))
                                .foregroundStyle(Palette.ink.opacity(0.9))
                            Text(item.text)
                                .font(.soft(12))
                                .lineSpacing(3)
                                .foregroundStyle(Palette.ink.opacity(0.6))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
        .padding(22)
        .frame(maxHeight: 460)
        .background(RoundedRectangle(cornerRadius: 18).fill(Palette.ink.opacity(0.04)))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Palette.ink.opacity(0.07)))
        .id(String(describing: kind))
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.5), value: String(describing: kind))
    }
}

// MARK: Safety

struct SafetyView: View {
    @ObservedObject var session: Session

    var body: some View {
        VStack(spacing: 22) {
            Spacer()
            TimelineView(.animation) { tl in
                let t = tl.date.timeIntervalSinceReferenceDate
                let k = 0.5 + 0.5 * sin(t * 2 * .pi / 10)
                Circle()
                    .fill(RadialGradient(colors: [Palette.cool.opacity(0.35), .clear], center: .center, startRadius: 4, endRadius: 110))
                    .frame(width: 160 + 50 * k, height: 160 + 50 * k)
            }
            .frame(height: 220)
            Text("Sab theek hai.")
                .font(.serif(34)).foregroundStyle(Palette.ink)
            Text("Haath neeche. Aankhein kholo. Normal saans lo.")
                .font(.serif(18, .regular)).foregroundStyle(Palette.ink.opacity(0.75))
            Text(session.safetyElapsed < 60
                 ? "1 minute aaraam · \(clock(60 - session.safetyElapsed))"
                 : "Chaho toh 3 : 3 se phir shuru karo. Na chaho toh bilkul theek.")
                .font(.soft(12)).foregroundStyle(Palette.ink.opacity(0.45))
                .padding(.top, 4)
            HStack(spacing: 12) {
                Button("3 : 3 se phir shuru") { session.restartGently() }
                    .buttonStyle(QuietButton(prominent: session.safetyElapsed >= 60))
                Button("Bhramari pe chalo") { session.skipAfterSafety() }
                    .buttonStyle(QuietButton())
                Button("Aaj ke liye bas") { session.finish() }
                    .buttonStyle(QuietButton())
            }
            .padding(.top, 10)
            Spacer()
        }
        .transition(.opacity)
    }
}

// MARK: Journal

struct JournalView: View {
    @ObservedObject var session: Session
    @EnvironmentObject var store: Store
    let onDone: () -> Void
    @State private var note = ""
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            Text(Date.now.formatted(date: .long, time: .omitted))
                .font(.soft(12)).tracking(2).textCase(.uppercase)
                .foregroundStyle(Palette.ink.opacity(0.4))
            Text(session.badDay ? "Chain nahi tooti." : "Ho gaya.")
                .font(.serif(40)).foregroundStyle(Palette.ink)
                .padding(.top, 10)
            Text("\(max(1, Int(session.minutesPracticed.rounded()))) minute")
                .font(.soft(12)).foregroundStyle(Palette.ink.opacity(0.45))
                .padding(.top, 6)

            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text("Aaj")
                    .font(.serif(22, .regular)).foregroundStyle(Palette.gold)
                TextField("", text: $note, prompt: Text("…").foregroundColor(Palette.ink.opacity(0.25)), axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(.serif(22, .regular))
                    .foregroundStyle(Palette.ink)
                    .lineLimit(1...5)
                    .focused($focused)
            }
            .padding(.bottom, 8)
            .overlay(alignment: .bottom) { Rectangle().fill(Palette.ink.opacity(0.15)).frame(height: 1) }
            .frame(maxWidth: 520)
            .padding(.top, 44)

            Text("Ek line. Jo bhi sach hai.")
                .font(.soft(11)).foregroundStyle(Palette.ink.opacity(0.35))
                .padding(.top, 10)

            HStack(spacing: 12) {
                Button("Likh liya") { save() }
                    .buttonStyle(QuietButton(prominent: true))
                    .keyboardShortcut(.return, modifiers: .command)
                Button("Bina likhe") { save() }
                    .buttonStyle(QuietButton())
            }
            .padding(.top, 34)
            Spacer()
        }
        .padding(.horizontal, 40)
        .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { focused = true } }
    }

    private func save() {
        store.add(Entry(date: .now, minutes: session.minutesPracticed, badDay: session.badDay,
                        note: note.trimmingCharacters(in: .whitespacesAndNewlines)))
        onDone()
    }
}
