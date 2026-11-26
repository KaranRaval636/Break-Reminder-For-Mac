import SwiftUI
import Charts

public struct StatisticsView: View {
    @ObservedObject var statisticsManager: StatisticsManager
    @State private var showingClearConfirmation = false
    @State private var selectedTimeRange: TimeRange = .week
    
    public enum TimeRange: String, CaseIterable, Identifiable {
        case week = "Last 7 Days"
        case twoWeeks = "Last 14 Days"
        public var id: String { rawValue }
        public var dayCount: Int {
            switch self {
            case .week: return 7
            case .twoWeeks: return 14
            }
        }
    }
    
    public init(statisticsManager: StatisticsManager = .shared) {
        self.statisticsManager = statisticsManager
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Statistics & Screen Score")
                            .font(.system(size: 24, weight: .bold))
                        Text("Local screen usage trends, break compliance, and ergonomic health metrics.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    
                    if !statisticsManager.records.isEmpty {
                        Button(role: .destructive) {
                            showingClearConfirmation = true
                        } label: {
                            Label("Clear Data", systemImage: "trash")
                                .font(.caption)
                        }
                        .buttonStyle(.bordered)
                        .confirmationDialog(
                            "Are you sure you want to clear all statistics history?",
                            isPresented: $showingClearConfirmation,
                            titleVisibility: .visible
                        ) {
                            Button("Clear All Statistics", role: .destructive) {
                                statisticsManager.clearAll()
                            }
                            Button("Cancel", role: .cancel) {}
                        }
                    }
                }
                
                // Screen Score Inspector Card
                screenScoreCard
                
                // Aggregate Metrics Grid
                metricsGrid
                
                // Charts Section
                chartsSection
                
                // Daily Breakdown List
                dailyHistorySection
                
                // Privacy & Medical Notice
                disclaimerNotice
            }
            .padding(24)
        }
    }
    
    // MARK: - Screen Score Inspector
    
    private var screenScoreCard: some View {
        let today = statisticsManager.todayRecord
        let score = ScreenScore.calculate(for: today)
        let breakdown = score.breakdown
        
        return VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 20) {
                // Circular Gauge
                ZStack {
                    Circle()
                        .stroke(Color.secondary.opacity(0.15), lineWidth: 10)
                        .frame(width: 84, height: 84)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(score.value) / 100.0)
                        .stroke(scoreColor(score.value), style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .frame(width: 84, height: 84)
                        .rotationEffect(.degrees(-90))
                    
                    VStack(spacing: 0) {
                        Text("\(score.value)")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                        Text("Score")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text("Today's Screen Score:")
                            .font(.headline)
                        Text(score.rating)
                            .font(.headline)
                            .foregroundColor(scoreColor(score.value))
                    }
                    
                    Text(score.ratingDescription)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            
            Divider()
            
            // Score Breakdown Points
            VStack(alignment: .leading, spacing: 8) {
                Text("Transparent Algorithm Breakdown")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ScoreBreakdownRow(title: "Base Starting Points", points: "+\(breakdown.basePoints)", color: .primary)
                    ScoreBreakdownRow(title: "Break Adherence", points: "+\(breakdown.breakAdherencePoints)", color: .green)
                    ScoreBreakdownRow(title: "Natural Breaks Bonus", points: "+\(breakdown.naturalBreakBonus)", color: .blue)
                    ScoreBreakdownRow(title: "Work-Rest Ratio", points: "+\(breakdown.workRestRatioPoints)", color: .teal)
                    ScoreBreakdownRow(title: "Skipped Breaks Penalty", points: "-\(breakdown.skipPenalty)", color: breakdown.skipPenalty > 0 ? .red : .secondary)
                    ScoreBreakdownRow(title: "Total Screen Score", points: "\(breakdown.totalScore) / 100", color: scoreColor(score.value))
                }
            }
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color(nsColor: .controlBackgroundColor)))
    }
    
    // MARK: - Metrics Grid
    
    private var metricsGrid: some View {
        let stats = statisticsManager.aggregate
        
        return LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 14) {
            StatCard(
                title: "Total Work Time",
                value: DateHelpers.formatDurationDetailed(stats.totalWorkTimeSeconds),
                subtitle: "\(stats.totalCompletedWorkSessions) completed sessions",
                systemImage: "laptopcomputer",
                tintColor: .blue
            )
            
            StatCard(
                title: "Breaks Completed",
                value: "\(stats.totalCompletedBreaks)",
                subtitle: DateHelpers.formatDurationDetailed(stats.totalBreakTimeSeconds) + " rested",
                systemImage: "cup.and.saucer.fill",
                tintColor: .green
            )
            
            StatCard(
                title: "Natural Breaks",
                value: "\(stats.totalNaturalBreaks)",
                subtitle: "Idle away-from-desk time",
                systemImage: "figure.walk",
                tintColor: .purple
            )
            
            StatCard(
                title: "Breaks Skipped",
                value: "\(stats.totalSkippedBreaks)",
                subtitle: stats.totalCompletedBreaks + stats.totalSkippedBreaks > 0
                    ? String(format: "%.0f%% adherence rate", (Double(stats.totalCompletedBreaks) / Double(stats.totalCompletedBreaks + stats.totalSkippedBreaks)) * 100)
                    : "No breaks scheduled",
                systemImage: "forward.fill",
                tintColor: stats.totalSkippedBreaks > 0 ? .orange : .secondary
            )
            
            StatCard(
                title: "Average Work Session",
                value: DateHelpers.formatDurationDetailed(stats.averageWorkSessionSeconds),
                subtitle: "Target: 45–50 mins",
                systemImage: "clock.arrow.2.circlepath",
                tintColor: .teal
            )
            
            StatCard(
                title: "Longest Session",
                value: DateHelpers.formatDurationDetailed(stats.longestWorkSessionSeconds),
                subtitle: "Uninterrupted screen time",
                systemImage: "exclamationmark.triangle",
                tintColor: stats.longestWorkSessionSeconds > 7200 ? .orange : .secondary
            )
        }
    }
    
    // MARK: - Charts Section
    
    private var chartsSection: some View {
        let recentData = statisticsManager.recentDays(count: selectedTimeRange.dayCount)
        
        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Usage & Compliance Trends")
                    .font(.headline)
                
                Spacer()
                
                Picker("", selection: $selectedTimeRange) {
                    ForEach(TimeRange.allCases) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 220)
            }
            
            // Chart: Work Time vs Break Time
            VStack(alignment: .leading, spacing: 10) {
                Text("Screen Time vs Rest Time (Hours)")
                    .font(.subheadline.bold())
                    .foregroundColor(.secondary)
                
                Chart {
                    ForEach(recentData) { item in
                        BarMark(
                            x: .value("Day", shortDate(item.dateIdentifier)),
                            y: .value("Hours", item.workTimeSeconds / 3600.0)
                        )
                        .foregroundStyle(Color.blue.gradient)
                        .position(by: .value("Type", "Work"))
                        
                        BarMark(
                            x: .value("Day", shortDate(item.dateIdentifier)),
                            y: .value("Hours", item.breakTimeSeconds / 3600.0)
                        )
                        .foregroundStyle(Color.teal.gradient)
                        .position(by: .value("Type", "Rest"))
                    }
                }
                .chartLegend(position: .top, alignment: .trailing)
                .frame(height: 180)
                .padding(.top, 8)
            }
            .padding(18)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color(nsColor: .controlBackgroundColor)))
            
            // Chart: Break Completion vs Skips
            VStack(alignment: .leading, spacing: 10) {
                Text("Break Adherence (Breaks Completed vs Skipped)")
                    .font(.subheadline.bold())
                    .foregroundColor(.secondary)
                
                Chart {
                    ForEach(recentData) { item in
                        BarMark(
                            x: .value("Day", shortDate(item.dateIdentifier)),
                            y: .value("Breaks", item.completedBreaks)
                        )
                        .foregroundStyle(Color.green.gradient)
                        .position(by: .value("Type", "Completed"))
                        
                        BarMark(
                            x: .value("Day", shortDate(item.dateIdentifier)),
                            y: .value("Breaks", item.skippedBreaks)
                        )
                        .foregroundStyle(Color.orange.gradient)
                        .position(by: .value("Type", "Skipped"))
                    }
                }
                .chartLegend(position: .top, alignment: .trailing)
                .frame(height: 160)
                .padding(.top, 8)
            }
            .padding(18)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color(nsColor: .controlBackgroundColor)))
        }
    }
    
    // MARK: - Daily History Section
    
    private var dailyHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Session History")
                .font(.headline)
            
            if statisticsManager.records.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "clock")
                            .font(.largeTitle)
                            .foregroundColor(.secondary.opacity(0.6))
                        Text("No sessions recorded yet")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Completed work intervals and breaks will appear here automatically.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(32)
                    Spacer()
                }
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(nsColor: .controlBackgroundColor)))
            } else {
                VStack(spacing: 8) {
                    ForEach(statisticsManager.records) { record in
                        let score = ScreenScore.calculate(for: record)
                        
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(DateHelpers.displayDateString(from: record.dateIdentifier))
                                    .font(.subheadline.weight(.semibold))
                                HStack(spacing: 8) {
                                    Text("Work: \(DateHelpers.formatDurationDetailed(record.workTimeSeconds))")
                                    Text("•")
                                    Text("Rest: \(DateHelpers.formatDurationDetailed(record.breakTimeSeconds))")
                                }
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            // Breaks Pill
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("\(record.completedBreaks)")
                                    .font(.caption.bold())
                                
                                if record.skippedBreaks > 0 {
                                    Text("•")
                                        .foregroundColor(.secondary)
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.orange)
                                    Text("\(record.skippedBreaks)")
                                        .font(.caption.bold())
                                }
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Color(nsColor: .separatorColor).opacity(0.2)))
                            
                            // Score Pill
                            Text("\(score.value) Score")
                                .font(.caption.bold())
                                .foregroundColor(scoreColor(score.value))
                                .frame(width: 75, alignment: .trailing)
                        }
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color(nsColor: .controlBackgroundColor)))
                    }
                }
            }
        }
    }
    
    // MARK: - Disclaimer Notice
    
    private var disclaimerNotice: some View {
        HStack(spacing: 12) {
            Image(systemName: "info.circle")
                .foregroundColor(.secondary)
            
            Text("Screen Score and rest metrics are designed as ergonomic wellness and habit-building indicators. They are not medical measurements or clinical diagnoses.")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color(nsColor: .separatorColor).opacity(0.15)))
    }
    
    // MARK: - Helpers
    
    private func scoreColor(_ val: Int) -> Color {
        if val >= 80 { return .green }
        if val >= 60 { return .teal }
        if val >= 40 { return .orange }
        return .red
    }
    
    private func shortDate(_ yyyyMMdd: String) -> String {
        let parts = yyyyMMdd.split(separator: "-")
        if parts.count == 3 {
            return "\(parts[1])/\(parts[2])"
        }
        return yyyyMMdd
    }
}

private struct ScoreBreakdownRow: View {
    let title: String
    let points: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(points)
                .font(.caption.bold())
                .foregroundColor(color)
        }
        .padding(.vertical, 2)
    }
}

public struct StatCard: View {
    public let title: String
    public let value: String
    public let subtitle: String
    public let systemImage: String
    public let tintColor: Color
    
    public init(
        title: String,
        value: String,
        subtitle: String,
        systemImage: String,
        tintColor: Color
    ) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.tintColor = tintColor
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: systemImage)
                    .foregroundColor(tintColor)
                    .font(.title3)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                Text(title)
                    .font(.subheadline.weight(.medium))
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(nsColor: .controlBackgroundColor)))
    }
}
