import SwiftUI

public struct PlannedBreaksModuleView: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var plannedBreakManager: PlannedBreakManager = .shared
    
    @State private var showingAddSheet: Bool = false
    @State private var newName: String = ""
    @State private var newHour: Int = 13
    @State private var newMinute: Int = 0
    @State private var newDuration: Int = 30
    @State private var selectedDays: Set<Int> = [2, 3, 4, 5, 6] // Mon-Fri
    
    public init(settings: AppSettings = .shared, plannedBreakManager: PlannedBreakManager = .shared) {
        self.settings = settings
        self.plannedBreakManager = plannedBreakManager
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Planned Breaks")
                            .font(.system(size: 24, weight: .bold))
                        Text("Schedule fixed daily events such as lunch, afternoon walks, or stretching sessions.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        showingAddSheet = true
                    }) {
                        Label("Add Planned Break", systemImage: "plus.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                // List of breaks
                if settings.plannedBreaks.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 38))
                            .foregroundColor(.secondary)
                        Text("No planned breaks scheduled yet.")
                            .font(.headline)
                        Text("Add scheduled events like lunch or walks to protect your rest routine.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(40)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color(nsColor: .controlBackgroundColor)))
                } else {
                    VStack(spacing: 12) {
                        ForEach(settings.plannedBreaks) { item in
                            plannedBreakRow(item)
                        }
                    }
                }
            }
            .padding(24)
        }
        .sheet(isPresented: $showingAddSheet) {
            addPlannedBreakSheet
        }
    }
    
    @ViewBuilder
    private func plannedBreakRow(_ item: PlannedBreak) -> some View {
        HStack(spacing: 16) {
            Toggle("", isOn: Binding(
                get: { item.isEnabled },
                set: { _ in plannedBreakManager.togglePlannedBreak(id: item.id) }
            ))
            .labelsHidden()
            
            VStack(alignment: .leading, spacing: 3) {
                Text(item.name)
                    .font(.headline)
                    .foregroundColor(item.isEnabled ? .primary : .secondary)
                
                Text("\(item.formattedTime) • \(item.durationMinutes) min • \(item.repeatDaysDescription)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: {
                plannedBreakManager.removePlannedBreak(id: item.id)
            }) {
                Image(systemName: "trash")
                    .foregroundColor(.red.opacity(0.8))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .controlBackgroundColor))
                .opacity(item.isEnabled ? 1.0 : 0.6)
        )
    }
    
    private var addPlannedBreakSheet: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Add Planned Break")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Break Name:")
                    .font(.subheadline)
                TextField("e.g. Lunch Break, Afternoon Walk", text: $newName)
                    .textFieldStyle(.roundedBorder)
            }
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Start Time:")
                        .font(.subheadline)
                    HStack {
                        Picker("Hour", selection: $newHour) {
                            ForEach(0..<24) { h in
                                Text(String(format: "%02d", h)).tag(h)
                            }
                        }
                        .frame(width: 80)
                        
                        Text(":")
                        
                        Picker("Min", selection: $newMinute) {
                            ForEach(Array(stride(from: 0, to: 60, by: 5)), id: \.self) { m in
                                Text(String(format: "%02d", m)).tag(m)
                            }
                        }
                        .frame(width: 80)
                    }
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Duration:")
                        .font(.subheadline)
                    Picker("", selection: $newDuration) {
                        Text("15 minutes").tag(15)
                        Text("30 minutes").tag(30)
                        Text("45 minutes").tag(45)
                        Text("60 minutes").tag(60)
                    }
                    .frame(width: 130)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Repeat on Days:")
                    .font(.subheadline)
                
                HStack(spacing: 8) {
                    let dayLabels = [
                        (2, "Mon"), (3, "Tue"), (4, "Wed"), (5, "Thu"), (6, "Fri"), (7, "Sat"), (1, "Sun")
                    ]
                    ForEach(dayLabels, id: \.0) { dayNum, label in
                        let isSelected = selectedDays.contains(dayNum)
                        Button(action: {
                            if isSelected {
                                selectedDays.remove(dayNum)
                            } else {
                                selectedDays.insert(dayNum)
                            }
                        }) {
                            Text(label)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(isSelected ? Color.accentColor : Color.gray.opacity(0.15))
                                )
                                .foregroundColor(isSelected ? .white : .primary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            Divider()
            
            HStack {
                Spacer()
                Button("Cancel") {
                    showingAddSheet = false
                }
                .buttonStyle(.bordered)
                
                Button("Save Planned Break") {
                    let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
                    let name = trimmed.isEmpty ? "Planned Break" : trimmed
                    let days = selectedDays.isEmpty ? [2, 3, 4, 5, 6] : Array(selectedDays)
                    
                    let newBreak = PlannedBreak(
                        name: name,
                        hour: newHour,
                        minute: newMinute,
                        durationMinutes: newDuration,
                        repeatDays: days
                    )
                    plannedBreakManager.addPlannedBreak(newBreak)
                    newName = ""
                    showingAddSheet = false
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 480, height: 380)
    }
}
