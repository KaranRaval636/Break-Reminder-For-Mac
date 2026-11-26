# Break Reminder — Manual QA Verification Checklist

This document details verification steps across all 10 product modules to validate behavior, performance, edge cases, and multi-display setups.

---

## Pre-Requisites & Launch Verification

- [ ] **App Launch**: Launch `BreakReminder.app`. Confirm Menu Bar icon appears in the macOS status bar.
- [ ] **Accessory Policy**: Closing the main window must **not** terminate the application.
- [ ] **Menu Bar Interaction**: Clicking the menu bar item displays current timer countdown, today's break stats, quick actions ("Start Work", "Take Break", "Pause"), and "Open Dashboard".
- [ ] **System Theme Support**: App respects macOS Dark Mode, Light Mode, and system-wide appearance changes immediately.

---

## Module A: Dashboard & Navigation

- [ ] **Hero Timer Dial**:
  - [ ] Shows animated circular ring reflecting countdown progress.
  - [ ] Displays status badge ("Working", "On Break", "Paused").
  - [ ] Formatted MM:SS time remaining updates accurately every second.
- [ ] **Screen Score Card**:
  - [ ] Displays live circular gauge (0–100) and rating ("Optimal", "Good", "Moderate", "Needs Attention").
  - [ ] Score adjusts accurately when breaks are completed or skipped.
- [ ] **Quick Action Controls**:
  - [ ] "Start Work" initiates a new cycle.
  - [ ] "Take Break" starts an immediate break overlay.
  - [ ] "Pause / Resume" toggles countdown without resetting session elapsed time.
- [ ] **Smart Pause Pill**:
  - [ ] When Smart Pause is active, displays green "Monitoring" pill.
  - [ ] When a pause trigger is active (e.g. video/idle), displays amber status badge showing reason.

---

## Module B: Screen Breaks

- [ ] **Break Profiles**:
  - [ ] Switching between *Balanced* (50m/5m), *Deep Work* (90m/15m), and *Eye Care / 20-20-20* (20m/20s) automatically updates interval settings.
  - [ ] Selecting *Custom* profile allows custom minute configurations.
- [ ] **Interval Controls**:
  - [ ] Work interval steppers clamp within valid bounds (5 to 180 mins).
  - [ ] Short break steppers clamp within 1 to 30 mins.
  - [ ] Long break steppers clamp within 5 to 60 mins.
  - [ ] Long break frequency stepper adjusts cycle count (every 2 to 10 cycles).
- [ ] **Snooze Limits**:
  - [ ] When snooze limit is set (e.g., 3 snoozes), after 3 snoozes the "Snooze" button is disabled on the break overlay.
  - [ ] Remaining snooze count is displayed on the break overlay.
- [ ] **Strict Mode**:
  - [ ] When "Strict Mode" is enabled, the "Skip" button is completely hidden from the break screen.
- [ ] **Pre-Break Notifications**:
  - [ ] When enabled, a notification fires 1 minute before work timer expires alerting the user to prepare for rest.

---

## Module C: Smart Pause Engine

- [ ] **System Idle Detection**:
  - [ ] Stop typing and moving mouse for configured idle threshold (e.g., 3 mins).
  - [ ] Verify Break Reminder pauses timer and shows "System Idle" status reason.
  - [ ] Move mouse; verify timer resumes.
- [ ] **Frontmost App & Exclusions**:
  - [ ] Add an app (e.g., Xcode or Final Cut Pro) to Excluded Apps.
  - [ ] Bring that app to the foreground; verify Smart Pause activates with reason `App: [AppName]`.
  - [ ] Switch away; verify Smart Pause clears.
- [ ] **Fullscreen Detection**:
  - [ ] Put a browser or video player in macOS native full-screen (`Fn + F` or green zoom button).
  - [ ] Verify Fullscreen Detector trips and pauses timer.
  - [ ] Exit full-screen; verify timer resumes.
- [ ] **Meeting & Recording Detection**:
  - [ ] Launch Zoom, FaceTime, Teams, or OBS Studio.
  - [ ] Verify detector flags active conference/recording session.
- [ ] **Postpone Grace Buffer**:
  - [ ] If a break is scheduled right as a meeting starts, verify break overlay is postponed gracefully.

---

## Module D: Wellness Reminders (Blink & Posture)

- [ ] **Blink Reminders**:
  - [ ] Enable Blink Reminders (20m interval).
  - [ ] Verify gentle non-intrusive notification appears with 20-20-20 guidance ("Look 20 feet away for 20 seconds").
  - [ ] Test suppression: Verify blink notifications are never delivered while a break overlay is active or when user is in a meeting.
- [ ] **Posture Reminders**:
  - [ ] Enable Posture Reminders (45m interval).
  - [ ] Verify ergonomic posture reminder notification fires.
- [ ] **Natural Break Detection**:
  - [ ] Step away from Mac for > 5 minutes.
  - [ ] Upon return, verify natural break is credited in statistics and work timer is refreshed to prevent an immediate redundant break.

---

## Module E: Planned Breaks

- [ ] **Create Planned Break**:
  - [ ] Add "Lunch Break" at a specific time (e.g., 1:00 PM, 45 minutes, Mon-Fri).
  - [ ] Confirm item persists and shows formatted time and active days.
- [ ] **Triggering**:
  - [ ] At scheduled time, Planned Break launches automatically with highest priority.
- [ ] **Day Filtering**:
  - [ ] Verify planned breaks configured for weekdays do not fire on weekends.

---

## Module F: Office Hours

- [ ] **Schedule Enforcement**:
  - [ ] Set Office Hours to 9:00 AM – 5:00 PM, Mon–Fri.
  - [ ] Verify timer runs during working hours.
  - [ ] Outside of configured hours, verify timer automatically pauses with "Outside Office Hours" status.
- [ ] **Manual Override**:
  - [ ] Toggle "Manual Override"; verify timer resumes working even outside scheduled hours.

---

## Module G: Statistics & Screen Score

- [ ] **Metric Aggregation**:
  - [ ] Complete 1 work session and 1 break. Verify daily record updates immediately.
  - [ ] Average work session duration and longest session values calculate accurately.
- [ ] **Swift Charts**:
  - [ ] Usage chart displays side-by-side work vs rest hours over the last 7 or 14 days.
  - [ ] Compliance chart renders completed vs skipped breaks.
- [ ] **Screen Score**:
  - [ ] Verify transparent breakdown card explains base points, adherence, natural breaks, and skip penalties.
  - [ ] Verify medical disclaimer notice is present.
- [ ] **Clear History**:
  - [ ] Click "Clear Data"; confirm alert dialog. After clearing, verify stats reset to 0.

---

## Module H: Appearance & Customization

- [ ] **Background Styles**:
  - [ ] Test *Aurora* (animated moving mesh gradients).
  - [ ] Test *Gradient* (smooth static hues).
  - [ ] Test *Dark* and *Light* minimalist styles.
- [ ] **Reduce Motion**:
  - [ ] Enable System Settings -> Accessibility -> Display -> "Reduce Motion".
  - [ ] Verify animated mesh transforms into a calm, static gradient without GPU spinning.
- [ ] **Box Breathing Guide**:
  - [ ] During break, verify animated 4-4-4 breathing circle ("Inhale", "Hold", "Exhale", "Hold") guides rest.
  - [ ] Toggle off Breathing Guide in settings; verify it hides.
- [ ] **Sound Presets**:
  - [ ] Audition Glass, Hero, Ping, Tink, Submarine, and Silent.
  - [ ] Verify correct chime plays at break start and end.
- [ ] **Break Screen Preview**:
  - [ ] Click "Preview Break Screen"; verify full preview modal opens with custom titles and tips.

---

## Module I: Automations & Shortcuts

- [ ] **App Intents**:
  - [ ] Run "Start Work Session" via Shortcuts or test button. Confirm work session begins.
  - [ ] Run "Take Break Now". Confirm break overlay appears.
  - [ ] Run "Toggle Timer Pause". Confirm timer pauses/resumes.
  - [ ] Run "Get Screen Score". Confirm dialog returns score.
- [ ] **Distributed Notifications**:
  - [ ] Listen to `com.breakreminder.BreakStarted` using `NSDistributedNotificationCenter` or script; confirm broadcast receives.
- [ ] **Custom Scripts**:
  - [ ] Enable script execution; set valid executable path (`chmod +x`). Confirm script runs on break start.
  - [ ] Verify invalid or non-executable scripts fail safely without crashes.

---

## Module J: Multi-Display & System Reliability

- [ ] **Multi-Display Coverage**:
  - [ ] Connect a secondary monitor. Trigger a break.
  - [ ] Verify overlay covers all connected screens simultaneously without gaps or flickering.
- [ ] **Display Disconnection / Hot-plugging**:
  - [ ] Unplug an external display while break is active. Verify remaining screen adapts smoothly.
- [ ] **Sleep & Wake Recovery**:
  - [ ] Put Mac to sleep during an active work session. Wake up after 15 minutes.
  - [ ] Verify elapsed time is caught up accurately without timer stalling or freezing.
- [ ] **Floating HUD**:
  - [ ] Enable Floating Countdown. Verify floating capsule appears.
  - [ ] Drag capsule to different screen locations. Confirm position persists across app restarts.
  - [ ] Verify floating HUD automatically hides during break overlays.
