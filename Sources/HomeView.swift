import SwiftUI

enum StartMode { case full, badDay, guided(URL), loggedElsewhere }

struct HomeView: View {
    @EnvironmentObject var store: Store
    let onStart: (StartMode) -> Void
    @State private var sheet: Sheet?

    enum Sheet: String, Identifiable { case prep, diary, settings; var id: String { rawValue } }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            Text(Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide)))
                .font(.soft(12)).tracking(2).textCase(.uppercase)
                .foregroundStyle(Palette.ink.opacity(0.4))
            Text("Sadhana")
                .font(.serif(64))
                .foregroundStyle(Palette.ink)
                .padding(.top, 10)
            Text("Baithna · Nadi Shodhana · Bhramari · Saakshi · Kalpana · Sankalpa")
                .font(.soft(12)).foregroundStyle(Palette.ink.opacity(0.45))
                .padding(.top, 6)

            ChainView().padding(.top, 36)

            VStack(spacing: 6) {
                Text("Nadi Shodhana  \(Int(store.effectiveRatio.counts.inhale)) : \(Int(store.effectiveRatio.counts.exhale))")
                    .font(.serif(17)).foregroundStyle(Palette.ink.opacity(0.8))
                Text(store.firstDay == 0 ? "Pehla din" : "Hafta \(store.week)")
                    .font(.soft(11)).foregroundStyle(Palette.ink.opacity(0.4))
            }
            .padding(.top, 30)

            if store.isGuidedDay {
                GuidedDayCard(onStart: onStart).padding(.top, 26)
            }

            HStack(spacing: 14) {
                Button("Shuru karo  ·  23 min") { onStart(.full) }
                    .buttonStyle(QuietButton(prominent: !store.isGuidedDay))
                    .keyboardShortcut(store.isGuidedDay ? nil : .defaultAction)
                Button("Bura din  ·  3 min") { onStart(.badDay) }
                    .buttonStyle(QuietButton())
            }
            .padding(.top, store.isGuidedDay ? 16 : 30)

            Text("Workout ke 5 minute baad · phone airplane mode · same jagah")
                .font(.soft(11)).foregroundStyle(Palette.ink.opacity(0.35))
                .padding(.top, 18)
            Spacer()

            HStack(spacing: 28) {
                link("Taiyari", .prep)
                link("Diary", .diary)
                link("Settings", .settings)
            }
            .padding(.bottom, 26)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(item: $sheet) { s in
            Group {
                switch s {
                case .prep: PrepView()
                case .diary: DiaryView()
                case .settings: SettingsView()
                }
            }
            .environmentObject(store)
            .preferredColorScheme(.dark)
        }
    }

    func link(_ title: String, _ s: Sheet) -> some View {
        Button(title) { sheet = s }
            .buttonStyle(.plain)
            .font(.soft(12))
            .foregroundStyle(Palette.ink.opacity(0.5))
    }
}

struct ChainView: View {
    @EnvironmentObject var store: Store

    var body: some View {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        VStack(spacing: 12) {
            HStack(spacing: 9) {
                ForEach((0..<14).reversed(), id: \.self) { back in
                    let day = cal.date(byAdding: .day, value: -back, to: today)!
                    let done = store.didPractice(on: day)
                    Circle()
                        .fill(done ? Palette.gold : Palette.ink.opacity(0.08))
                        .overlay(Circle().stroke(back == 0 ? Palette.ink.opacity(0.5) : .clear, lineWidth: 1))
                        .frame(width: 9, height: 9)
                        .shadow(color: done ? Palette.gold.opacity(0.6) : .clear, radius: 4)
                }
            }
            Text(store.streak == 0 ? "Aaj se chain shuru" :
                    "\(store.streak) din · chain nahi tooti" + (store.didPractice(on: today) ? "  ·  aaj ho gaya" : ""))
                .font(.soft(11)).foregroundStyle(Palette.ink.opacity(0.45))
        }
    }
}

struct GuidedDayCard: View {
    @EnvironmentObject var store: Store
    let onStart: (StartMode) -> Void

    var body: some View {
        VStack(spacing: 12) {
            Text("Aaj guided din hai")
                .font(.serif(19, .regular)).foregroundStyle(Palette.gold)
            Text("Aaj sadhana ki jagah koi aur tumhe 20 minute guide karega.")
                .font(.soft(12)).foregroundStyle(Palette.ink.opacity(0.55))
            HStack(spacing: 10) {
                if let url = store.guidedURL {
                    Button("Chalao · \(url.deletingPathExtension().lastPathComponent)") { onStart(.guided(url)) }
                        .buttonStyle(QuietButton(prominent: true))
                        .keyboardShortcut(.defaultAction)
                }
                Button("Medito kholo") { NSWorkspace.shared.open(URL(string: "https://meditofoundation.org")!) }
                    .buttonStyle(QuietButton(prominent: store.guidedURL == nil))
                Button("Medito se kar liya · likho") { onStart(.loggedElsewhere) }
                    .buttonStyle(QuietButton())
            }
        }
        .padding(.vertical, 18).padding(.horizontal, 26)
        .background(RoundedRectangle(cornerRadius: 18).fill(Palette.gold.opacity(0.05)))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Palette.gold.opacity(0.18)))
    }
}
