import Foundation
import SwiftUI

struct Entry: Codable, Identifiable {
    var id = UUID()
    var date: Date
    var minutes: Double
    var badDay: Bool
    var note: String
}

final class Store: ObservableObject {
    @Published var entries: [Entry] = []

    private static let d = UserDefaults.standard
    @Published var sankalpa = Store.migratedSankalpa { didSet { Self.d.set(sankalpa, forKey: "sankalpa") } }
    @Published var ratioRaw = Store.d.string(forKey: "ratio") ?? Ratio.auto.rawValue { didSet { Self.d.set(ratioRaw, forKey: "ratio") } }
    @Published var waitForMe = Store.d.object(forKey: "waitForMe") as? Bool ?? true { didSet { Self.d.set(waitForMe, forKey: "waitForMe") } }
    /// Weekday (1 = Sunday … 7 = Saturday) for the guided-audio day; 0 = off.
    @Published var guidedWeekday = Store.d.object(forKey: "guidedWeekday") as? Int ?? 1 { didSet { Self.d.set(guidedWeekday, forKey: "guidedWeekday") } }
    @Published var guidedPath = Store.d.string(forKey: "guidedPath") ?? "" { didSet { Self.d.set(guidedPath, forKey: "guidedPath") } }
    @Published var voiceVolume = Store.d.object(forKey: "voiceVolume") as? Double ?? 1.0 { didSet { Self.d.set(voiceVolume, forKey: "voiceVolume") } }
    @Published var firstDay: Double = Store.d.double(forKey: "firstDay") { didSet { Self.d.set(firstDay, forKey: "firstDay") } }

    private static var migratedSankalpa: String {
        let s = d.string(forKey: "sankalpa")
        return (s == nil || s == "Main nimitt hoon.") ? "Main bas zariya hoon." : s!
    }

    private let url: URL = {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Sadhana", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("diary.json")
    }()

    init() {
        if let d = try? Data(contentsOf: url),
           let e = try? JSONDecoder().decode([Entry].self, from: d) {
            entries = e.sorted { $0.date > $1.date }
        }
    }

    func add(_ e: Entry) {
        if firstDay == 0 { firstDay = Calendar.current.startOfDay(for: e.date).timeIntervalSince1970 }
        entries.insert(e, at: 0)
        save()
    }

    func update(_ e: Entry) {
        if let i = entries.firstIndex(where: { $0.id == e.id }) { entries[i] = e; save() }
    }

    func delete(_ e: Entry) {
        entries.removeAll { $0.id == e.id }
        save()
    }

    private func save() {
        let enc = JSONEncoder()
        enc.outputFormatting = .prettyPrinted
        try? enc.encode(entries).write(to: url, options: .atomic)
    }

    /// Week of practice, 1-based, counted from the first session.
    var week: Int {
        guard firstDay > 0 else { return 1 }
        let days = Calendar.current.dateComponents([.day], from: Date(timeIntervalSince1970: firstDay),
                                                   to: Calendar.current.startOfDay(for: Date())).day ?? 0
        return days / 7 + 1
    }

    var ratioSetting: Ratio {
        get { Ratio(rawValue: ratioRaw) ?? .auto }
        set { ratioRaw = newValue.rawValue }
    }

    var effectiveRatio: Ratio {
        switch ratioSetting {
        case .auto: return week >= 3 ? .r48 : .r44
        default: return ratioSetting
        }
    }

    var isGuidedDay: Bool {
        guidedWeekday != 0 && Calendar.current.component(.weekday, from: Date()) == guidedWeekday
    }

    var guidedURL: URL? {
        guard !guidedPath.isEmpty, FileManager.default.fileExists(atPath: guidedPath) else { return nil }
        return URL(fileURLWithPath: guidedPath)
    }

    func didPractice(on day: Date) -> Bool {
        entries.contains { Calendar.current.isDate($0.date, inSameDayAs: day) }
    }

    var streak: Int {
        let cal = Calendar.current
        var day = cal.startOfDay(for: Date())
        if !didPractice(on: day) { day = cal.date(byAdding: .day, value: -1, to: day)! }
        var n = 0
        while didPractice(on: day) {
            n += 1
            day = cal.date(byAdding: .day, value: -1, to: day)!
        }
        return n
    }
}
