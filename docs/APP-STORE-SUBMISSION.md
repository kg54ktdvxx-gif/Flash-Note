# App Store Submission Guide — Flash Note

## What Works

### Upload: `asc builds upload` (CLI)

```bash
# 1. Archive
xcodebuild clean archive \
  -project FlashNote.xcodeproj \
  -scheme FlashNoteApp \
  -configuration Release \
  -archivePath /tmp/FlashNote.xcarchive \
  -destination "generic/platform=iOS" \
  -allowProvisioningUpdates

# 2. Export IPA
xcodebuild -exportArchive \
  -archivePath /tmp/FlashNote.xcarchive \
  -exportPath /tmp/FlashNoteExport \
  -exportOptionsPlist /tmp/FlashNoteExportOptions.plist \
  -allowProvisioningUpdates

# 3. Upload
asc builds upload --app 6759323134 --ipa /tmp/FlashNoteExport/FlashNote.ipa --wait
```

**ExportOptions.plist** (create at `/tmp/FlashNoteExportOptions.plist`):
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store-connect</string>
    <key>teamID</key>
    <string>ML4L5QJ99D</string>
</dict>
</plist>
```

### Attach Build to Version: `asc versions attach-build` (CLI)

```bash
# List builds to get build ID
asc builds list --app 6759323134 --limit 3 --output table

# Attach to existing version
asc versions attach-build \
  --version-id "VERSION_ID" \
  --build "BUILD_ID"
```

### Submit for Review: App Store Connect Web UI (ONLY reliable method)

1. Go to https://appstoreconnect.apple.com
2. Navigate to Flash Note Pro > App Store > version
3. Verify build is attached
4. Add Review Notes explaining any non-obvious features
5. Click "Submit for Review"

**This is how all previous submissions were done** (Xcode Organizer or web UI). CLI submission has never worked reliably.

## What Does NOT Work

### `asc submit create` — Creates orphaned review submissions

```bash
# DO NOT USE — creates empty submissions that can't be cancelled
asc submit create --app 6759323134 --version "1.0" --build "BUILD_ID" --confirm
```

**Problem**: If this command fails partway (wrong version string, API error, etc.), it creates an empty `reviewSubmission` in `READY_FOR_REVIEW` state that:
- Cannot be cancelled (`Resource is not in cancellable state`)
- Cannot be deleted
- Cannot be submitted (no items)
- Counts toward the **concurrency limit of 5** per app

Once 5 of these accumulate, no new submissions can be created via API. The only workaround is to submit through the web UI or wait for Apple to auto-expire them.

**Feb 25, 2026 incident**: 4 orphaned empty submissions blocked CLI submission of build 4. Had to submit via web UI.

### `asc publish appstore --submit` — Same underlying issue

Uses `submit create` internally, same orphan risk.

### `fastlane submit` — Not installed, previously failed

AwakeApp had fastlane configured but it failed with ASC API compatibility errors. fastlane is not currently installed.

## Build Number Management

Build numbers must be bumped in `project.yml` across ALL 5 targets, then regenerated:

```bash
# Edit project.yml — change CURRENT_PROJECT_VERSION in all targets
# Then regenerate:
/opt/homebrew/bin/xcodegen generate
```

Targets that need matching build numbers:
- FlashNoteApp
- FlashNoteWatch
- FlashNoteWidgets
- FlashNoteShareExtension
- FlashNoteIntents

## App IDs and Auth

| Item | Value |
|------|-------|
| App ID | `6759323134` |
| Bundle ID | `com.flashnote.app` |
| Team ID | `ML4L5QJ99D` |
| ASC API Key ID | `C5TM86N9PG` |
| ASC API Issuer | `a5c4390d-c45c-4453-a560-d6234fcd501e` |
| ASC auth | System Keychain (via `asc auth login`) |
| App Store version string | `1.0` (NOT `1.0.0` — ASC strips trailing `.0`) |

## Review Notes Template

Always include a review note for non-obvious features. Example for Voice Notes:

> **Voice Notes**: From the capture screen, tap the microphone icon in the bottom-right toolbar. Tap the red mic button to start recording. Speak, then tap stop. Transcribed text appears in real-time. Tap Save to create the note. It appears in the Inbox tab with a waveform icon.

## Rejection History

### Build 4 — Rejected Mar 1, 2026 (Guideline 2.1 - Performance - App Completeness)

**Issue**: "The app displayed an error message on recording" — iPad Air 11-inch (M3), iPadOS 26.3. Alert: "Voice Capture Error: Speech recognition couldn't process your audio."

**Root cause**: Build 4's fix (`requiresOnDeviceRecognition = recognizer.supportsOnDeviceRecognition`) was incomplete. `supportsOnDeviceRecognition` reports hardware capability, NOT model availability. On M3 iPad it returns `true`, so `requiresOnDeviceRecognition` was set to `true`, but on-device speech models weren't downloaded on the review device → immediate recognition failure.

**Fix (Build 5)**:
1. Set `requiresOnDeviceRecognition = false` unconditionally — let the system auto-select on-device vs server recognition. On-device is still used when models are available.
2. Added explicit microphone permission check (`AVAudioApplication.requestRecordPermission()`) before starting audio engine
3. Guarded recognition error callback — `SFSpeechRecognitionTask` fires error on normal completion too; now skips error if a final result was already received

### Build 3 — Rejected Feb 23, 2026 (Guideline 2.3 - Accurate Metadata)

**Issue**: "the app does not allow us to save the text created from our speech"

**Root cause**: `requiresOnDeviceRecognition = true` in `VoiceCaptureService.swift`. Apple's review devices are clean/managed — on-device speech models aren't pre-downloaded. Recognition failed silently: waveform animated but no text appeared, Save button never showed.

**Fix (Build 4)**:
1. Changed to `recognizer.supportsOnDeviceRecognition` — falls back to server recognition when on-device models aren't available
2. Added error propagation — recognition failures now show an alert instead of failing silently

### Build 2 — Rejected Feb 20, 2026 (Guideline 2.3 + 5.1.1)

**Issues**:
1. Voice Notes had no UI entry point (mic button missing)
2. Missing privacy policy link

**Fix (Build 3)**:
1. Added mic button to capture bottom bar
2. Added privacy policy link in Settings

## Checklist Before Submission

- [ ] All tests pass (`xcodebuild test`)
- [ ] Build number bumped in project.yml (all 5 targets)
- [ ] `xcodegen generate` run after project.yml change
- [ ] Archive builds with zero errors
- [ ] Build uploaded and processing state is VALID
- [ ] Build attached to correct App Store version
- [ ] Review notes added for non-obvious features
- [ ] If rejected previously: reply to rejection thread in ASC with fix explanation

## Lessons Learned

1. **`requiresOnDeviceRecognition` must be `false`** — `supportsOnDeviceRecognition` reports hardware capability, NOT model availability. Apple's review devices (clean/managed) may support on-device but lack downloaded models. Always leave `requiresOnDeviceRecognition = false` and let the system auto-select.

2. **ASC version string drops trailing `.0`** — `1.0.0` in Xcode becomes `1.0` in App Store Connect. Use the ASC version string when querying the API.

3. **Never use `asc submit create` until the orphan bug is fixed** — one failed call permanently consumes a concurrency slot. Submit via web UI.

4. **Always add Review Notes** — Reviewers test on clean devices with limited time. Spell out exactly how to find and use every feature mentioned in metadata.

5. **Reply to rejections in ASC** — When resubmitting after rejection, reply in the rejection thread explaining what changed. This goes to the same reviewer.
