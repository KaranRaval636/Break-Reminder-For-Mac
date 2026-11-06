import SwiftUI

public struct StatisticsView: View {
    @ObservedObject var statisticsManager: StatisticsManager
    @State private var showingClearConfirmation = false
    
    public init(statisticsManager: StatisticsManager = .shared) {
        self.statisticsManager = statisticsManager
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            // Aggregate metric cards
            let stats = statisticsManager.aggregate
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                StatCard(
                    title: "Work Sessions",
                    value: "\(stats.totalCompletedWorkSessions)",
                    subtitle: DateHelpers.formatDurationDetailed(stats.totalWorkTimeSeconds) + " total",
                    systemImage: "laptopcomputer",
                    tintColor: .blue
                )
                
                StatCard(
                    title: "Breaks Taken",
                    value: "\(stats.totalCompletedBreaks)",
                    subtitle: DateHelpers.formatDurationDetailed(stats.totalBreakTimeSeconds) + " rested",
                    systemImage: "cup.and.saucer.fill",
                    tintColor: .teal
                )
                
                StatCard(
                    title: "Breaks Skipped",
                    value: "\(stats.totalSkippedBreaks)",
                    subtitle: stats.totalCompletedBreaks + stats.totalSkippedBreaks > 0
                        ? String(format: "%.0f%% compliance", (Double(stats.totalCompletedBreaks) / Double(stats.totalCompletedBreaks + stats.totalSkippedBreaks)) * 100)
                        : "No breaks yet",
                    systemImage: "forward.fill",
                    tintColor: .orange
                )
            }
            .padding(.horizontal)
            
            Divider()
            
            // Daily breakdown list
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Daily History")
                        .font(.headline)
                    Spacer()
                    if !statisticsManager.records.isEmpty {
                        Button(role: .destructive, action: {
                            showingClearConfirmation = true
                        }) {
                            Text("Clear History")
                                .font(.caption)
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.red)
                    }
                }
                .padding(.horizontal)
                
                if statisticsManager.records.isEmpty {
                    VStack(spacing: 8) {
                        Spacer()
                        Image(systemName: "chart.bar.doc.horizontal")
                            .font(.system(size: 36))
                            .foregroundColor(.secondary.opacity(0.5))
                        Text("No session history recorded yet.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("Complete work sessions and breaks to see your statistics here.")
                            .font(.caption)
                            .foregroundColor(.secondary.opacity(0.7))
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(statisticsManager.records) { record in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(DateHelpers.displayDateString(from: record.dateIdentifier))
                                    .font(.system(size: 13, weight: .semibold))
                                HStack(spacing: 10) {
                                    Text("Work: \(DateHelpers.formatDurationDetailed(record.workTimeSeconds))")
                                    Text("•")
                                    Text("Break: \(DateHelpers.formatDurationDetailed(record.breakTimeSeconds))")
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            HStack(spacing: 12) {
                                Label("\(record.completedWorkSessions)", systemImage: "briefcase.fill")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                
                                Label("\(record.completedBreaks)", systemImage: "cup.and.saucer.fill")
                                    .font(.caption)
                                    .foregroundColor(.teal)
                                
                                if record.skippedBreaks > 0 {
                                    Label("\(record.skippedBreaks)", systemImage: "forward.fill")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .listStyle(.inset(alternatesRowBackgrounds: true))
                }
            }
        }
        .padding(.vertical, 16)
        .frame(minWidth: 540, minHeight: 420)
        .alert("Clear All Statistics?", isPresented: $showingClearConfirmation) {
            Button("Clear All", role: .destructive) {
                statisticsManager.clearAll()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently remove all your past session records and totals.")
        }
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
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Image(systemName: systemImage)
                    .foregroundColor(tintColor)
            }
            
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
            
            Text(subtitle)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }
}
