import SwiftUI

public struct OfficeHoursModuleView: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var officeHoursManager: OfficeHoursManager
    
    private let weekdays = [
        (1, "Sun", "Sunday"),
        (2, "Mon", "Monday"),
        (3, "Tue", "Tuesday"),
        (4, "Wed", "Wednesday"),
        (5, "Thu", "Thursday"),
        (6, "Fri", "Friday"),
        (7, "Sat", "Saturday")
    ]
    
    public init(
        settings: AppSettings = .shared,
        officeHoursManager: OfficeHoursManager = .shared
    ) {
        self.settings = settings
        self.officeHoursManager = officeHoursManager
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Office Hours")
                        .font(.system(size: 24, weight: .bold))
                    Text("Automatically pause reminders and timers outside your scheduled working hours.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Live Status Card
                statusCard
                
                // Master Toggle & Override
                VStack(alignment: .leading, spacing: 16) {
                    Toggle("Enable Office Hours Schedule", isOn: $settings.officeHoursEnabled)
                        .font(.headline)
                        .onChange(of: settings.officeHoursEnabled) { _ in
                            officeHoursManager.evaluateOfficeHours()
                        }
                    
                    Text("When active, Break Reminder will only track work sessions and issue break alerts during your configured hours.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if settings.officeHoursEnabled {
                        Divider()
                        
                        Toggle("Manual Override (Keep Active Outside Hours)", isOn: $settings.officeHoursOverride)
                            .font(.subheadline.weight(.medium))
                            .onChange(of: settings.officeHoursOverride) { _ in
                                officeHoursManager.evaluateOfficeHours()
                            }
                        
                        Text("Temporarily unpauses the timer when working overtime without needing to change your daily schedule.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(18)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(nsColor: .controlBackgroundColor)))
                
                if settings.officeHoursEnabled {
                    // Time Configuration
                    VStack(alignment: .leading, spacing: 18) {
                        Text("Daily Schedule")
                            .font(.headline)
                        
                        HStack(spacing: 32) {
                            // Start Time
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Work Day Starts")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(.secondary)
                                
                                HStack(spacing: 8) {
                                    Picker("Hour", selection: $settings.officeHoursStartHour) {
                                        ForEach(0..<24, id: \.self) { hour in
                                            Text(String(format: "%02d", hour)).tag(hour)
                                        }
                                    }
                                    .labelsHidden()
                                    .frame(width: 70)
                                    
                                    Text(":")
                                        .font(.headline)
                                    
                                    Picker("Minute", selection: $settings.officeHoursStartMinute) {
                                        ForEach(Array(stride(from: 0, to: 60, by: 5)), id: \.self) { min in
                                            Text(String(format: "%02d", min)).tag(min)
                                        }
                                    }
                                    .labelsHidden()
                                    .frame(width: 70)
                                    
                                    Text(formattedPeriod(hour: settings.officeHoursStartHour))
                                        .font(.caption.bold())
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Divider()
                                .frame(height: 50)
                            
                            // End Time
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Work Day Ends")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(.secondary)
                                
                                HStack(spacing: 8) {
                                    Picker("Hour", selection: $settings.officeHoursEndHour) {
                                        ForEach(0..<24, id: \.self) { hour in
                                            Text(String(format: "%02d", hour)).tag(hour)
                                        }
                                    }
                                    .labelsHidden()
                                    .frame(width: 70)
                                    
                                    Text(":")
                                        .font(.headline)
                                    
                                    Picker("Minute", selection: $settings.officeHoursEndMinute) {
                                        ForEach(Array(stride(from: 0, to: 60, by: 5)), id: \.self) { min in
                                            Text(String(format: "%02d", min)).tag(min)
                                        }
                                    }
                                    .labelsHidden()
                                    .frame(width: 70)
                                    
                                    Text(formattedPeriod(hour: settings.officeHoursEndHour))
                                        .font(.caption.bold())
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                        }
                        
                        Divider()
                        
                        // Active Days
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Active Weekdays")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Button("Mon - Fri") {
                                    settings.officeHoursDays = [2, 3, 4, 5, 6]
                                    officeHoursManager.evaluateOfficeHours()
                                }
                                .buttonStyle(.link)
                                .font(.caption)
                                
                                Text("•")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                                
                                Button("All Days") {
                                    settings.officeHoursDays = [1, 2, 3, 4, 5, 6, 7]
                                    officeHoursManager.evaluateOfficeHours()
                                }
                                .buttonStyle(.link)
                                .font(.caption)
                            }
                            
                            HStack(spacing: 8) {
                                ForEach(weekdays, id: \.0) { id, shortName, fullName in
                                    let isSelected = settings.officeHoursDays.contains(id)
                                    Button(action: {
                                        toggleDay(id)
                                    }) {
                                        Text(shortName)
                                            .font(.caption.weight(isSelected ? .bold : .medium))
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 8)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(isSelected ? Color.accentColor : Color(nsColor: .separatorColor).opacity(0.3))
                                            )
                                            .foregroundColor(isSelected ? .white : .primary)
                                    }
                                    .buttonStyle(.plain)
                                    .help(fullName)
                                }
                            }
                        }
                    }
                    .padding(18)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(nsColor: .controlBackgroundColor)))
                    
                    // Timezone notice
                    HStack(spacing: 12) {
                        Image(systemName: "globe.americas.fill")
                            .foregroundColor(.accentColor)
                            .font(.title3)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Local Timezone Active")
                                .font(.caption.bold())
                            Text("Schedule operates according to \(TimeZone.current.localizedName(for: .standard, locale: .current) ?? "system timezone").")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.accentColor.opacity(0.08)))
                }
            }
            .padding(24)
        }
    }
    
    // MARK: - Status Card
    
    private var statusCard: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(statusColor)
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(statusTitle)
                    .font(.headline)
                Text(statusSubtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(statusColor.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(statusColor.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private var statusColor: Color {
        guard settings.officeHoursEnabled else { return .secondary }
        if settings.officeHoursOverride { return .orange }
        return officeHoursManager.isOutsideOfficeHours ? .purple : .green
    }
    
    private var statusTitle: String {
        guard settings.officeHoursEnabled else {
            return "Office Hours Inactive"
        }
        if settings.officeHoursOverride {
            return "Office Hours Overridden (Active)"
        }
        if officeHoursManager.isOutsideOfficeHours {
            return "Outside Office Hours (Timer Paused)"
        } else {
            return "Inside Office Hours (Timer Active)"
        }
    }
    
    private var statusSubtitle: String {
        guard settings.officeHoursEnabled else {
            return "Timer and reminders run continuously according to your normal preferences."
        }
        if settings.officeHoursOverride {
            return "Manual override is currently forcing Break Reminder to remain active."
        }
        if officeHoursManager.isOutsideOfficeHours {
            return "Work session timer is quietly paused until your next scheduled office hours begin."
        } else {
            return "Schedule is active: \(formattedTime(hour: settings.officeHoursStartHour, minute: settings.officeHoursStartMinute)) to \(formattedTime(hour: settings.officeHoursEndHour, minute: settings.officeHoursEndMinute))."
        }
    }
    
    private func formattedPeriod(hour: Int) -> String {
        return hour >= 12 ? "PM" : "AM"
    }
    
    private func formattedTime(hour: Int, minute: Int) -> String {
        let period = hour >= 12 ? "PM" : "AM"
        let displayHour = hour % 12 == 0 ? 12 : hour % 12
        return String(format: "%d:%02d %@", displayHour, minute, period)
    }
    
    private func toggleDay(_ day: Int) {
        if settings.officeHoursDays.contains(day) {
            if settings.officeHoursDays.count > 1 {
                settings.officeHoursDays.removeAll { $0 == day }
            }
        } else {
            settings.officeHoursDays.append(day)
            settings.officeHoursDays.sort()
        }
        officeHoursManager.evaluateOfficeHours()
    }
}
