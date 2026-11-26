# Break Reminder — Privacy Architecture & Security Disclosure

Break Reminder is designed from the ground up as a private, local-first macOS wellness companion. Your work habits, screen usage, and schedule are your personal information.

---

## 1. Core Principles

- **Zero Network Traffic**: Break Reminder has no backend, no cloud servers, no account registration, and no tracking pixels. It does not initiate any outbound HTTP/HTTPS connections.
- **Zero Telemetry / Zero Analytics**: There are no third-party analytics SDKs (no Firebase, no Mixpanel, no Amplitude, no Sentry).
- **Zero Content Recording**: Break Reminder **never** logs keystrokes, never captures screenshots, never taps the microphone, and never accesses the camera.
- **100% Local Storage**: All settings, planned schedules, and statistics are stored locally on your device in your macOS user defaults domain.

---

## 2. Detailed Technical Audit of macOS APIs

Break Reminder uses standard, privacy-preserving macOS APIs to monitor system state without requesting invasive permissions.

| Feature | macOS API / Technique | Privacy & Security Guarantees |
| :--- | :--- | :--- |
| **Idle Detection** | `CGEventSource.secondsSinceLastEventType(.combinedSessionState, .any)` | Queries only the duration of system inactivity as a floating-point number. **Does not capture keystrokes, mouse coordinates, or click events.** |
| **Active App Tracking** | `NSWorkspace.shared.frontmostApplication` & `NSWorkspace.didActivateApplicationNotification` | Reads only the bundle identifier (e.g., `com.apple.dt.Xcode`) and localized name of the active app to evaluate user-configured pause rules. |
| **Fullscreen Detection** | `CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID)` | Inspects only window geometry (`CGRect` bounds) relative to `NSScreen.screens` to determine if a window covers the menu bar. **Does not read window contents, pixel data, or private document titles.** |
| **Meeting Detection** | Process table inspection + active window matching | Matches against known conference client bundle IDs (`us.zoom.xos`, `com.microsoft.teams2`, `com.cisco.webexmeetings`, `com.apple.FaceTime`). **Zero access to microphone audio, webcam video, or meeting participants.** |
| **Screen Recording Detection** | Running process inspection | Detects active recording software (`com.obsproject.obs-studio`, `com.loom.desktop`, `com.simplexsolutionsinc.cleanshotx`). No access to recorded screen buffers. |
| **Video Playback Detection** | Process presence and frontmost window status | Monitors players like QuickTime Player, VLC, and IINA without inspecting video content. |
| **Audio Alerts** | `NSSound` & system sound resources (`/System/Library/Sounds/`) | Uses macOS built-in system sound effects. No external audio streams or microphone access. |
| **Notifications** | `UNUserNotificationCenter` | Delivers local user notifications. No remote push notifications or APNs tokens. |
| **Automations & Scripts** | `Process` & `DistributedNotificationCenter` | **Disabled by default.** Broadcasts event names only (`com.breakreminder.BreakStarted`). Custom scripts only run if explicitly enabled and set to a specific local file by the user. |

---

## 3. macOS Permissions Matrix

| Permission | Requested? | Reason |
| :--- | :--- | :--- |
| **Accessibility (`AXIsProcessTrusted`)** | **No** | Break Reminder does not control other applications, manipulate UI elements, or record input. |
| **Screen Recording (`CGRequestScreenCaptureAccess`)** | **No** | Fullscreen detection uses geometry metadata from `CGWindowListCopyWindowInfo` without pixel capture. |
| **Microphone & Camera** | **No** | Break Reminder does not record audio or video. |
| **Full Disk Access** | **No** | Break Reminder strictly accesses its own sandboxed container / local defaults. |
| **Notifications** | **Yes (Optional)** | Requested once to deliver break alerts and gentle eye/posture reminders when scheduled. |

---

## 4. Screen Score Transparency

The **Screen Score (0–100)** is calculated purely on your Mac using a deterministic, transparent algorithm:
- Base starting score: 35 points
- Break completion adherence: up to 35 points
- Natural away-from-desk breaks: up to 15 bonus points
- Work-to-rest ratio (5–10 min rest per hour): up to 20 points
- Skipped break deductions: -6 points per skip

> [!NOTE]
> Screen Score is an ergonomic habit indicator to help you build healthy screen habits. It is **not** a clinical diagnosis or medical measurement.
