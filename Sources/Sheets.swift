import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct SheetFrame<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(title).font(.serif(26)).foregroundStyle(Palette.ink)
                Spacer()
                Button("Done") { dismiss() }
                    .buttonStyle(QuietButton())
                    .keyboardShortcut(.cancelAction)
            }
            .padding(.bottom, 18)
            content
        }
        .padding(30)
        .frame(width: 620, height: 600)
        .background(Palette.bgTop)
    }
}

struct PrepView: View {
    var body: some View {
        SheetFrame(title: "Taiyari") {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    group("Jagah", "Roz ek hi jagah. Kamre ka ek kona, deewar ke paas, jahan koi disturb na kare. Ek mat ya moda hua kambal. Roz same jagah pe baithne se sharir ko khud signal milta hai.")
                    group("Kab", "Workout ke baad, 5 minute ruk ke, taaki dil ki dhadkan normal ho jaaye. Pasina ponch lo. Pet khaali ya halka.")
                    group("Phone", "Airplane mode, screen neeche. Timer ye app hai. Beech mein time dekhna nahi hai. Har exercise se pehle ek ghanti. Time poora hone pe bhi wahi ghanti; jitni der chaho ruko, space dabao toh aage.")

                    HStack(alignment: .top, spacing: 24) {
                        Canvas { ctx, size in
                            let s = min(size.width / 300, size.height / 320)
                            ctx.scaleBy(x: s, y: s)
                            Art.glow(&ctx, at: CGPoint(x: 150, y: 170), r: 120, color: Palette.gold, strength: 0.25)
                            Art.figure(&ctx)
                        }
                        .frame(width: 170, height: 180)
                        VStack(alignment: .leading, spacing: 10) {
                            heading("Kaise baithna hai")
                            bullet("Sukhasana", "Paalthi. Kulhe ke neeche moda kambal, taaki ghutne kulhe se neeche rahein.")
                            bullet("Vajrasana", "Edhiyon pe. Ghutno mein dikkat ho toh mat karo.")
                            bullet("Kursi", "Pair zameen pe flat, peeth kursi se door, seedhi.")
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        heading("Posture, sar se neeche tak")
                        bullet("Sar", "Thodi halki si andar, jaise gardan ke peeche koi dhaaga upar kheench raha ho.")
                        bullet("Jabda", "Dheela. Daant halke se alag, hont band.")
                        bullet("Jeebh", "Upar ke daanton ke peeche taaloo ko chhooti hui.")
                        bullet("Kandhe", "Ek baar kaan tak uthao, phir poori tarah gira do.")
                        bullet("Reedh", "Seedhi, akdi hui nahi. Alert, tension mein nahi.")
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        heading("Kab rukna hai")
                        Text("Nadi shodhana mein chakkar, ghabraahat, dil tez, ya saans atakne jaisa lage: turant esc dabao. Haath neeche, aankhein kholo, normal saans. 1 minute baad chaho toh 3 : 3 se phir. Pehle panic ho chuka hai, isliye ye rule seriously.")
                            .font(.soft(13)).lineSpacing(3).foregroundStyle(Palette.warm.opacity(0.85))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        heading("Keyboard")
                        Text("space  aage  ·  esc  ruko  ·  p  pause  ·  i  body info")
                            .font(.soft(12)).foregroundStyle(Palette.ink.opacity(0.55))
                    }
                }
                .padding(.bottom, 20)
            }
        }
    }

    func heading(_ s: String) -> some View {
        Text(s).font(.serif(17, .regular)).foregroundStyle(Palette.ink)
    }

    func group(_ title: String, _ text: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            heading(title)
            Text(text).font(.soft(13)).lineSpacing(3).foregroundStyle(Palette.ink.opacity(0.65))
        }
    }

    func bullet(_ b: String, _ text: String) -> some View {
        (Text(b + "  ").font(.soft(13, .medium)).foregroundColor(Palette.gold.opacity(0.85))
         + Text(text).font(.soft(13)).foregroundColor(Palette.ink.opacity(0.65)))
            .lineSpacing(3)
            .fixedSize(horizontal: false, vertical: true)
    }
}

struct DiaryView: View {
    @EnvironmentObject var store: Store

    var body: some View {
        SheetFrame(title: "Diary") {
            if store.entries.isEmpty {
                Text("Abhi kuch nahi. Pehli sadhana ke baad yahan likha dikhega.")
                    .font(.soft(13)).foregroundStyle(Palette.ink.opacity(0.5))
                Spacer()
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(store.entries) { e in
                            HStack(alignment: .firstTextBaseline, spacing: 18) {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(e.date.formatted(.dateTime.day().month(.abbreviated)))
                                        .font(.soft(12, .medium)).foregroundStyle(Palette.ink.opacity(0.7))
                                    Text("\(max(1, Int(e.minutes.rounded()))) min" + (e.badDay ? " · bura din" : ""))
                                        .font(.soft(10)).foregroundStyle(Palette.ink.opacity(0.35))
                                }
                                .frame(width: 90, alignment: .leading)
                                (Text("Aaj ").foregroundColor(Palette.gold.opacity(0.85))
                                 + Text(e.note.isEmpty ? "—" : e.note).foregroundColor(Palette.ink.opacity(0.8)))
                                    .font(.serif(16, .regular))
                                    .textSelection(.enabled)
                                Spacer()
                            }
                            .padding(.vertical, 14)
                            .overlay(alignment: .bottom) { Rectangle().fill(Palette.ink.opacity(0.06)).frame(height: 1) }
                            .contextMenu {
                                Button("Hatao", role: .destructive) { store.delete(e) }
                            }
                        }
                    }
                }
            }
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject var store: Store

    var body: some View {
        SheetFrame(title: "Settings") {
            VStack(alignment: .leading, spacing: 26) {
                row("Sankalpa", "Apni line mil jaaye toh yahan badal do.") {
                    TextField("", text: $store.sankalpa)
                        .textFieldStyle(.plain).font(.serif(18, .regular))
                        .padding(.bottom, 6)
                        .overlay(alignment: .bottom) { Rectangle().fill(Palette.ink.opacity(0.15)).frame(height: 1) }
                }
                row("Nadi shodhana ginti", "Hafte 1–2: 4:4. Hafte 3 se: 4:8. Mushkil lage toh 3:3.") {
                    Picker("", selection: Binding(get: { store.ratioSetting }, set: { store.ratioSetting = $0 })) {
                        ForEach(Ratio.allCases) { Text($0.label).tag($0) }
                    }
                    .labelsHidden().frame(width: 260)
                }
                row("Phase khatam hone pe", "Ghanti bajegi. Uske baad:") {
                    Picker("", selection: $store.waitForMe) {
                        Text("Mera intezaar karo").tag(true)
                        Text("Apne aap aage badho").tag(false)
                    }
                    .pickerStyle(.segmented).labelsHidden().frame(width: 320)
                }
                row("Guided din", "Hafte mein ek din sadhana ki jagah ek 20 minute guided meditation. Medito app se, ya apni koi audio file.") {
                    HStack(spacing: 12) {
                        Picker("", selection: $store.guidedWeekday) {
                            Text("Band").tag(0)
                            ForEach(1...7, id: \.self) { d in
                                Text(Calendar.current.weekdaySymbols[d - 1]).tag(d)
                            }
                        }
                        .labelsHidden().frame(width: 140)
                        Button(store.guidedURL == nil ? "Audio file chuno…" : store.guidedURL!.lastPathComponent) { pickAudio() }
                            .buttonStyle(QuietButton())
                        if store.guidedURL != nil {
                            Button("Hatao") { store.guidedPath = "" }
                                .buttonStyle(.plain).font(.soft(11)).foregroundStyle(Palette.ink.opacity(0.45))
                        }
                    }
                }
                row("Awaaz (guide)", "") {
                    Slider(value: $store.voiceVolume, in: 0...1).frame(width: 260)
                }
                Spacer()
            }
        }
    }

    func pickAudio() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.audio]
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url { store.guidedPath = url.path }
    }

    func row<C: View>(_ title: String, _ hint: String, @ViewBuilder _ c: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.serif(16, .regular)).foregroundStyle(Palette.ink)
            if !hint.isEmpty {
                Text(hint).font(.soft(11)).foregroundStyle(Palette.ink.opacity(0.45))
            }
            c()
        }
    }
}
