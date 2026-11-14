import SwiftUI
import AppKit

@main
struct SadhanaApp: App {
    @StateObject private var store = Store()
    @NSApplicationDelegateAdaptor private var delegate: AppDelegate

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .preferredColorScheme(.dark)
                .frame(minWidth: 880, minHeight: 640)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1000, height: 700)
        .commands { CommandGroup(replacing: .newItem) {} }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
    func applicationDidFinishLaunching(_ notification: Notification) {
        MainActor.assumeIsolated { Snapshot.runIfRequested() }
        _ = AudioEngine.shared // warm up synth + drone
    }
}

struct Backdrop: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [Palette.bgTop, Palette.bgBottom], startPoint: .top, endPoint: .bottom)
            RadialGradient(colors: [Palette.gold.opacity(0.07), .clear], center: .init(x: 0.5, y: 0.35),
                           startRadius: 10, endRadius: 520)
        }
        .ignoresSafeArea()
    }
}

final class Router: ObservableObject {
    @Published var session: Session?
}

struct RootView: View {
    @EnvironmentObject var store: Store
    @StateObject private var router = Router()

    var body: some View {
        ZStack {
            Backdrop()
            if let s = router.session {
                SessionView(session: s) { router.session = nil }
                    .transition(.opacity)
            } else {
                HomeView { mode in
                    let s: Session
                    switch mode {
                    case .full: s = Session(store: store, badDay: false)
                    case .badDay: s = Session(store: store, badDay: true)
                    case .guided(let url): s = Session(store: store, guided: url)
                    case .loggedElsewhere: s = Session(store: store, externalMinutes: 20)
                    }
                    router.session = s
                    if s.stage == .running { s.start() }
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.8), value: router.session == nil)
        .onAppear {
            // Dev aid: SADHANA_AUTOSTART=full|bad starts a session immediately.
            guard let mode = ProcessInfo.processInfo.environment["SADHANA_AUTOSTART"] else { return }
            let s = Session(store: store, badDay: mode == "bad")
            router.session = s
            s.start()
        }
    }
}

extension Font {
    static func serif(_ size: CGFloat, _ weight: Font.Weight = .light) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }
    static func soft(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

struct QuietButton: ButtonStyle {
    var prominent = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.soft(13, prominent ? .medium : .regular))
            .padding(.horizontal, prominent ? 26 : 16)
            .padding(.vertical, prominent ? 12 : 8)
            .foregroundStyle(prominent ? Palette.bgTop : Palette.ink.opacity(0.8))
            .background(
                Capsule().fill(prominent ? Palette.gold.opacity(configuration.isPressed ? 0.7 : 0.92)
                               : Palette.ink.opacity(configuration.isPressed ? 0.14 : 0.07))
            )
            .overlay(Capsule().stroke(Palette.ink.opacity(prominent ? 0 : 0.12)))
            .contentShape(Capsule())
    }
}

func clock(_ s: Double) -> String {
    let v = Int(s.rounded(.down))
    return String(format: "%d:%02d", v / 60, v % 60)
}
