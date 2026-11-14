import SwiftUI

/// Dev aid: SADHANA_SNAPSHOT=/some/dir renders key screens to PNGs and quits.
enum Snapshot {
    @MainActor static func runIfRequested() {
        guard let dir = ProcessInfo.processInfo.environment["SADHANA_SNAPSHOT"] else { return }
        let store = Store()
        func render<V: View>(_ v: V, _ name: String) {
            let r = ImageRenderer(content: ZStack { Backdrop(); v }
                .environmentObject(store).environment(\.colorScheme, .dark).frame(width: 1000, height: 700))
            r.scale = 1
            if let img = r.nsImage, let tiff = img.tiffRepresentation,
               let png = NSBitmapImageRep(data: tiff)?.representation(using: .png, properties: [:]) {
                try? png.write(to: URL(fileURLWithPath: dir).appendingPathComponent(name + ".png"))
            }
        }
        render(HomeView { _ in }, "0-home")
        store.guidedWeekday = Calendar.current.component(.weekday, from: Date())
        render(HomeView { _ in }, "0-home-guided")
        store.guidedWeekday = 1
        let shots: [(Int, Double)] = [(0, 55), (1, 200), (2, 50), (3, 125), (4, 45), (4, 110), (4, 140), (5, 5), (6, 5), (6, 15), (6, 30)]
        for (i, e) in shots {
            let s = Session(store: store, badDay: false)
            s.debugJump(to: i, elapsed: e)
            render(SessionView(session: s) {}, "\(i + 1)-\(s.phase.title)-\(Int(e))")
        }
        exit(0)
    }
}
