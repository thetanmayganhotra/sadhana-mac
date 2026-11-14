# Sadhana (Mac)

A quiet daily breathing and meditation practice app for macOS, guided by a calm Hindi voice.

Native SwiftUI, no accounts, no internet.

## The practice

A full session goes through these phases, with a voice, a pacer and simple illustrations:

1. **Settle** — arrive and sit
2. **Nadi shodhana** — alternate-nostril breathing with a visual pacer (3:3, 4:4, 4:8, or automatic by week)
3. **Bhramari** — humming bee breath
4. **Witness** — sit and watch
5. **Visualise**
6. **Sankalpa** — intention
7. **Close**

Other ways to start: a short **bad-day** version, a **guided** session from an audio file, or just **log** a practice you did somewhere else.

Also: a streak chain on the home screen, a diary/journal after each session, a prep sheet, and a safety screen with who should avoid which practice.

## Build

```bash
./build.sh      # -> build/Sadhana.app and build/Sadhana.dmg (universal: arm64 + x86_64)
```

Only needs the Xcode Command Line Tools. Targets macOS 14+.

## Voice and sounds

The guiding voice lines are pre-rendered with a neural Hindi voice (`hi-IN-SwaraNeural` via edge-tts):

```bash
pip install edge-tts
python scripts/make_voice.py     # -> Resources/voice/
python scripts/make_bell.py      # -> Resources/sounds/
```

Credits for sounds are in `Resources/CREDITS.txt`.

## Layout

```
Sources/
  App.swift          app + routing
  Model.swift        phases, ratios, cues, plans
  Session.swift      session engine (timing, pacer)
  SessionView.swift  in-session UI
  HomeView.swift     home + streak chain
  Sheets.swift       prep, diary, settings
  Store.swift        local history
  Audio.swift        voice + bell playback
  Illustrations.swift
scripts/             voice, bell and icon generators
Resources/           voice clips, sounds
```
