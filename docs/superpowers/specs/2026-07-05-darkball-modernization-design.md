# Darkball (TATATA) Modernization — Design

**Date:** 2026-07-05
**Status:** Approved

## Goal

Bring the 2015 Objective-C "temporal dead reckoning" trainer (Darkball / TATATA)
from iOS 7.1 + dead dependencies to a state where it builds on Xcode 26,
runs correctly on modern iPhones (iOS 15+), and is App Store–submittable.
Keep the code Objective-C. Do not change gameplay, timing, or visual design —
the CADisplayLink game loop and timing feel are the point of the app.

## Current state

- Xcode project `Darkball.xcodeproj`, ~4,300 lines of Objective-C in `TATATA/`.
- Deployment target iOS 7.1; last commit April 2015.
- Bundled binary frameworks, all dead or obsolete: Parse, ParseUI,
  ParseFacebookUtils, ParseCrashReporting, Bolts, Crashlytics.
- Parse usage: app-open analytics, automatic anonymous `PFUser` with run
  counter, survey answers saved to the Parse user (`SurveyView`), and trial
  results logged to a `results` class (`ViewController`).
- Game Center: 2015-era authentication and `GKScore` submission, leaderboard
  view via deprecated `GKGameCenterViewController` API shapes.
- Launch: `Default.png` / `Default-568h@2x.png` launch images → app letterboxes
  on modern iPhones. Hardcoded 320/568-point layout assumptions.
- Linked-but-unused frameworks: StoreKit, CoreLocation, MediaPlayer,
  libstdc++.6 (removed from modern iOS SDKs).

## Design

### 1. Project & build modernization

- Remove the six bundled dead frameworks and all references/build phases,
  including the Crashlytics run-script phase.
- Drop unused framework links (StoreKit, CoreLocation, MediaPlayer,
  libstdc++.6.dylib).
- Deployment target → iOS 15.0. Update settings to Xcode 26 recommendations.
- Stay Objective-C throughout; no source rewrites beyond what the removals
  and deprecations require.

### 2. Replace Parse with local storage

- New `TrialStore` class (ObjC): appends trial-result records — same fields
  currently sent to Parse — to a JSON file in Application Support. Research
  data keeps accumulating on-device.
- Survey answers and run count → `NSUserDefaults`.
- Parse analytics calls deleted outright.
- Survey flow and trial logging keep working; only the backend changes.

### 3. Modernize Game Center

- `GKLocalPlayer.local.authenticateHandler` for auth.
- Score submission via the modern `submitScore` class API (iOS 14+).
- Keep the existing leaderboard ID; works if the App Store Connect entry
  still exists, fails gracefully (silently disabled UI) if not.

### 4. Modern devices & App Store readiness

- Launch screen storyboard replaces `Default*.png` (required for full-screen
  rendering on modern devices).
- Fix hardcoded screen-size assumptions and deprecated UIKit calls; respect
  safe areas (notch / Dynamic Island).
- Asset catalog with app icon set (derived from existing artwork).
- `PrivacyInfo.xcprivacy` privacy manifest (UserDefaults access reason).
- Info.plist cleanup; bump version/build.

## Error handling

- Game Center unavailable / not signed in: hide or disable leaderboard UI;
  never block gameplay.
- TrialStore write failures: log and continue; gameplay must never stall on
  storage.

## Testing / verification

- Build for iOS 18 simulator with zero errors.
- Play multiple trials; verify score, best, accuracy, sparkline, and survey.
- Verify trial records appear in the local JSON store.
- Verify full-screen (no letterboxing) and safe-area-correct layout on a
  modern iPhone simulator (e.g. iPhone 16 Pro).
- Device signing / App Store submission handled after simulator verification.

## Out of scope

- Gameplay, timing, or visual redesign.
- Swift rewrite.
- Re-hosting a Parse-compatible server.
- Trial-data export UI (can be added later if research use resumes).
