import SwiftUI

public struct MainWindowView: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var timerManager: TimerManager
    @ObservedObject var statisticsManager: StatisticsManager
    
    @State private var selectedSection: NavigationSection? = .dashboard
    
    public init(
        settings: AppSettings = .shared,
        timerManager: TimerManager = .shared,
        statisticsManager: StatisticsManager = .shared,
        initialSection: NavigationSection = .dashboard
    ) {
        self.settings = settings
        self.timerManager = timerManager
        self.statisticsManager = statisticsManager
        self._selectedSection = State(initialValue: initialSection)
    }
    
    public var body: some View {
        NavigationSplitView {
            List(NavigationSection.allCases, selection: $selectedSection) { section in
                NavigationLink(value: section) {
                    Label(section.title, systemImage: section.systemImage)
                }
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 210, ideal: 230, max: 280)
            .navigationTitle("Break Reminder")
        } detail: {
            Group {
                switch selectedSection ?? .dashboard {
                case .dashboard:
                    DashboardView(
                        timerManager: timerManager,
                        settings: settings,
                        statisticsManager: statisticsManager
                    )
                case .screenBreaks:
                    ScreenBreaksModuleView(
                        settings: settings,
                        timerManager: timerManager
                    )
                case .smartPause:
                    SmartPauseModuleView(
                        settings: settings,
                        timerManager: timerManager
                    )
                case .wellness:
                    WellnessModuleView(
                        settings: settings
                    )
                case .plannedBreaks:
                    PlannedBreaksModuleView(
                        settings: settings
                    )
                case .officeHours:
                    OfficeHoursModuleView(
                        settings: settings
                    )
                case .statistics:
                    StatisticsView(
                        statisticsManager: statisticsManager
                    )
                case .appearance:
                    AppearanceModuleView(
                        settings: settings,
                        timerManager: timerManager
                    )
                case .automations:
                    AutomationsModuleView(
                        settings: settings
                    )
                case .generalSettings:
                    GeneralSettingsModuleView(
                        settings: settings,
                        timerManager: timerManager
                    )
                }
            }
            .frame(minWidth: 640, minHeight: 520)
            .toolbar {
                ToolbarItemGroup(placement: .automatic) {
                    // Quick state pill
                    HStack(spacing: 6) {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 8, height: 8)
                        Text(DateHelpers.formatRemainingTime(timerManager.remainingSeconds))
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(6)
                    
                    // Quick timer toggle
                    if timerManager.status == .working {
                        Button(action: { timerManager.pauseTimer() }) {
                            Image(systemName: "pause.fill")
                        }
                        .help("Pause current focus session")
                    } else if timerManager.status == .paused {
                        Button(action: { timerManager.resumeTimer() }) {
                            Image(systemName: "play.fill")
                        }
                        .help("Resume focus session")
                    } else if timerManager.status == .idle {
                        Button(action: { timerManager.startWorkSession() }) {
                            Image(systemName: "play.fill")
                        }
                        .help("Start focus session")
                    }
                }
            }
        }
        .preferredColorScheme(settings.theme.colorScheme)
    }
    
    private var statusColor: Color {
        switch timerManager.status {
        case .idle: return .secondary
        case .working: return .green
        case .paused: return .orange
        case .onBreak: return .teal
        }
    }
}
