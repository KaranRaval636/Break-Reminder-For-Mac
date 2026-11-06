# Break Reminder for macOS

**Break Reminder** is a native macOS wellness and productivity utility designed to help users take timely, restorative breaks during focused work sessions. Built purely with Swift, SwiftUI, AppKit, and Apple's system frameworks, it runs quietly in the macOS menu bar and deploys a gentle, multi-monitor soft-blocking break overlay across all connected displays when your work interval finishes.

---

## Features

- **Menu Bar Utility**: Runs as a lightweight agent (`LSUIElement = true`) in the macOS menu bar using SwiftUI `MenuBarExtra`. Shows live countdown and session status.
- **Reliable Date-Based Engine**: Calculates countdowns using wall-clock timestamps (`Date.timeIntervalSince`) rather than naive timer decrements. Gracefully handles Mac sleep/wake, system time shifts, and app restarts.
- **Multi-Monitor Soft-Blocking Overlay**:
  - Dynamically detects all connected displays via `NSScreen`.
  - Spawns borderless `NSWindow` instances at `.modalPanel` window level.
  - Configured with `[.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]` to float above standard apps and fullscreen spaces without disabling system emergency shortcuts or compromising security.
  - Hot-pluggable: Automatically synchronizes windows when monitors are plugged in, unplugged, or rearranged.
- **Snooze & Skip Controls**: Configurable 5-minute snooze and skip actions directly from the overlay and menu bar.
- **Configurable Preferences**:
  - Work interval (1–180 minutes, default 50m)
  - Short break duration (1–60 minutes, default 5m)
  - Long break duration (1–60 minutes, default 15m)
  - Long break frequency (default every 4 sessions)
  - Snooze duration & toggles
  - Multi-display vs. primary display only toggle
  - Audio chimes & system notifications
  - Launch at login (`SMAppService.mainApp`)
  - Light, Dark, and System appearance modes
- **Local Privacy-First Statistics**: Tracks completed work sessions, breaks taken, skipped breaks, total work time, and rest time locally without cloud services or analytics.
- **Automated DMG Distribution**: Self-contained script to compile, sign, stage, and compress a distributable DMG installer with an Applications shortcut.

---

## Architecture & Project Structure

```
BreakReminder/
├── App/
│   ├── BreakReminderApp.swift        # SwiftUI App entry point with MenuBarExtra
│   └── AppDelegate.swift             # NSApplicationDelegate lifecycle & activation policy
│
├── Models/
│   ├── TimerState.swift              # TimerStatus, BreakType, TimerSnapshot
│   ├── AppSettings.swift             # User settings persistence & validation
│   └── DailyStatistics.swift         # DailyRecord & AggregateStatistics models
│
├── Managers/
│   ├── TimerManager.swift            # Central timer state machine & persistence
│   ├── BreakWindowManager.swift      # Multi-monitor soft-blocking NSWindow manager
│   ├── NotificationManager.swift     # UserNotifications integration
│   ├── SoundManager.swift            # AVFoundation / NSSound chimes
│   ├── StatisticsManager.swift       # Session logging & daily history
│   ├── LaunchAtLoginManager.swift    # SMAppService launch-at-login integration
│   └── AppWindowManager.swift        # Managed single-instance AppKit windows
│
├── Views/
│   ├── MenuBarView.swift             # Rich menu bar popover interface
│   ├── BreakScreenView.swift         # Full-screen wellness overlay interface
│   ├── SettingsView.swift            # Native tabbed preferences window
│   ├── StatisticsView.swift          # Session history & metrics dashboard
│   ├── DashboardView.swift           # Standalone dashboard component
│   └── Components/
│       ├── WellnessBackground.swift  # Animated ambient backdrop
│       └── ProgressRingView.swift    # Circular countdown progress ring
│
├── Utilities/
│   └── DateHelpers.swift             # Time interval formatters & date helpers
│
└── Resources/
    ├── Assets.xcassets/              # AppIcon in 1x/2x resolutions (16 to 1024px)
    ├── Info.plist                    # App metadata and LSUIElement agent flag
    └── BreakReminder.entitlements    # Hardened runtime entitlements
```

---

## System Requirements

- **Operating System**: macOS 13.0 (Ventura) or later
- **Architecture**: Apple Silicon (arm64) and Intel (x86_64) Universal
- **IDE**: Xcode 15.0 or later

---

## How to Build & Run in Xcode

1. Open `BreakReminder.xcodeproj` in Xcode:
   ```bash
   open BreakReminder.xcodeproj
   ```
2. Select the **BreakReminder** scheme and **My Mac** destination.
3. Press **Cmd + R** to run or **Cmd + B** to build.
4. The application icon will appear in your macOS menu bar (top right). Click it to reveal the controls.

---

## Running Unit Tests

The test suite covers work session completion, break countdowns, pause/resume, snooze, skip, long break scheduling, state persistence, timer recovery, multi-monitor window management, and screen hot-plugging.

Run tests via Xcode (**Cmd + U**) or via terminal:

```bash
xcodebuild -project BreakReminder.xcodeproj \
    -scheme BreakReminder \
    -derivedDataPath .build/DerivedData \
    -destination 'platform=macOS' \
    test
```

---

## DMG Packaging & Distribution

To create a clean release DMG:

```bash
./scripts/build-dmg.sh
```

The script performs the following:
1. Compiles the app with the `Release` configuration.
2. Stages `BreakReminder.app` and an `/Applications` symlink.
3. Ad-hoc codesigns the app bundle locally (or signs with Developer ID if configured).
4. Packages a compressed DMG disk image at `dist/BreakReminder-1.0.0.dmg`.

### Developer ID Signing & Notarization (Optional)

When preparing an official build for private distribution:

```bash
export DEVELOPER_ID_APPLICATION="Developer ID Application: Your Name (TEAMID)"
export NOTARIZE=true
export APPLE_ID="your.appleid@example.com"
export APPLE_PASSWORD="app-specific-password"
export TEAM_ID="TEAMID"

./scripts/build-dmg.sh
```

---

## Installing & Gatekeeper Notes (Unsigned / Ad-Hoc Builds)

For personal distribution without an Apple Developer subscription:

1. Double-click `dist/BreakReminder-1.0.0.dmg`.
2. Drag **Break Reminder** to **Applications**.
3. Launch Break Reminder:
   - If macOS Gatekeeper displays a security warning ("cannot be opened because the developer cannot be verified"):
     - **Option 1**: Right-click (or Control-click) `Break Reminder` in `/Applications` and select **Open**, then click **Open** in the dialog.
     - **Option 2**: Run the following terminal command once:
       ```bash
       xattr -cr /Applications/BreakReminder.app
       ```

---

## Manual QA Checklist for Testing on a Real Mac

| Test Item | Steps | Expected Result |
| :--- | :--- | :--- |
| **1. Menu Bar Launch** | Launch app. | Icon appears in menu bar; no dock icon appears (`LSUIElement`). |
| **2. Start Session** | Click icon -> "Start Work Session". | Status changes to "Working", countdown starts ticking. |
| **3. Pause & Resume** | Click "Pause", wait 5s, click "Resume". | Timer halts while paused, resumes with exact remaining seconds preserved. |
| **4. Instant Break** | While working, click "Break Now". | Soft-blocking overlay appears over all active displays. |
| **5. Overlay Controls** | Test "Snooze", "Skip Break", and "Finish Break". | Window disappears; timer transitions appropriately; stats record event. |
| **6. Multi-Display** | Connect a second monitor during a break. | Overlay immediately replicates onto the newly connected monitor. Disconnecting cleans up the window. |
| **7. Preferences** | Open "Preferences...", change work interval to 25m, toggle sound off. | Changes persist across app quit and relaunch. |
| **8. Statistics** | Open "View Statistics". | Displays accurate counts for completed sessions, breaks, and minutes. |
| **9. Mac Sleep/Wake** | Start timer, put Mac to sleep for 1 minute, wake Mac. | Countdown accurately accounts for elapsed wall-clock time. |
| **10. Window Closing** | Open Settings or Statistics, then click red close button (x). | Window closes; application remains running in menu bar. |

---

## License

Created for Native macOS Break Reminder. Released under the MIT License.
