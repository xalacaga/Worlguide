# Feature Spec: Background audio playback

**Status**: approved
**Created**: 2026-08-15
**Domain module(s) touched**: iOS: `WGPlayback` (`AVSpeechSynthesizerAudioPlayer`), `ios/project.yml` (background mode capability)

## Overview

Live testing (`specs/013`) proved the core flow works, but speech stops the
moment the screen locks or the user switches apps — a hard blocker for a
walking-tour audio guide, where the phone is expected to be in a pocket
while the user walks and listens. Nothing configures an `AVAudioSession`
or declares the `audio` background mode, so iOS suspends the app (and its
audio) as soon as it's backgrounded.

## User scenarios

- As a user listening to a POI's description, I want the audio to keep
  playing when I lock my phone or switch to another app, so that I can
  walk and listen without keeping WorldGuide in the foreground.

## Requirements

- [ ] `ios/project.yml`'s App target declares the `audio` entry in
  `UIBackgroundModes` — required before iOS will let any audio continue
  once backgrounded, regardless of app code.
- [ ] `AVSpeechSynthesizerAudioPlayer.play(_:)` activates an
  `AVAudioSession` with category `.playback` (mode `.spokenAudio`) before
  speaking — `.playback` is what tells iOS this audio should continue
  in the background and duck/mix per system rules, not stop.
- [ ] `AVSpeechSynthesizerAudioPlayer.stop()` deactivates the session
  (`.notifyOthersOnDeactivation`) — a good citizen: releases the audio
  route so other apps' paused audio (e.g. Music) can resume once
  WorldGuide is done.
- [ ] `pause()`/`resume()` do **not** touch the session — a paused
  session should stay active (Apple's guidance: deactivating on pause
  drops the Now Playing/route state a user expects to still control from
  Control Center).
- [ ] `AVAudioSession` is iOS-only (unlike `AVSpeechSynthesizer`, it does
  not exist on macOS) — this module also builds for macOS so `swift test`
  can run without a simulator (docs/adr/0006), so the session-configuring
  code is `#if os(iOS)`-gated. This means `swift test` (macOS-hosted, per
  the existing CI `ios` job) never compiles or exercises this specific
  code path — verified instead by `xcodebuild build` against a real iOS
  destination, same as every other App-target-adjacent check this
  project already relies on.

## Out of scope

- Now Playing / lock-screen media controls (`MPNowPlayingInfoCenter`,
  `MPRemoteCommandCenter`) — a real enhancement once background playback
  itself works, not required to keep audio playing.
- Interruption handling (phone call arrives mid-speech, etc.) — accepted
  as a follow-up; `AVSpeechSynthesizer` degrades reasonably on its own
  (stops on interruption) even without explicit handling.
- Continuous/auto-advancing playback across multiple POIs.

## Provenance / data impact

None — this only changes how already-fetched `ContentPackage.text` is
played, not what's fetched or shown.

## Review checklist

- [x] No implementation detail leaked into this spec
- [x] Requirements are testable
- [x] Constitution principles respected (see `.specify/memory/constitution.md`)
- [x] Follow-up ADR filed if this changes a structural boundary — not
  needed: `AVSpeechSynthesizerAudioPlayer` already owns "the AVFoundation
  adapter for `AudioPlaying`" (specs/010); audio session configuration is
  the same adapter's responsibility, not a new module boundary.
