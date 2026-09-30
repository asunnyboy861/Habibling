import SwiftUI
import SwiftData

struct AddEditHabitView: View {
    var habit: Habit?

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var checkIns: CheckInService
    @EnvironmentObject private var purchases: PurchaseManager

    @State private var name = ""
    @State private var iconSymbol = "checkmark.circle"
    @State private var colorHex = "#F6968E"
    @State private var type: HabitType = .binary
    @State private var targetValue = 1.0
    @State private var unitLabel = ""
    @State private var scheduleType: HabitScheduleType = .daily
    @State private var selectedWeekdays: Set<Int> = [2, 3, 4, 5, 6]
    @State private var everyNDays = 2
    @State private var daysPerWeek = 3
    @State private var reminderEnabled = false
    @State private var reminderTime = Date.from(hour: 9, minute: 0)
    @State private var showDeleteConfirm = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Habit") {
                    TextField("Name", text: $name)
                    HStack {
                        Image(systemName: iconSymbol)
                            .foregroundStyle(Color(hex: colorHex))
                            .frame(width: 36, height: 36)
                            .background(Color(hex: colorHex).opacity(0.14))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        TextField("Unit label (optional)", text: $unitLabel)
                    }
                }
                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 10) {
                        ForEach(AppTheme.iconChoices, id: \.self) { icon in
                            Button {
                                iconSymbol = icon
                            } label: {
                                Image(systemName: icon)
                                    .frame(width: 34, height: 34)
                                    .background(iconSymbol == icon ? Color(hex: colorHex).opacity(0.25) : .clear)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                Section("Color") {
                    HStack {
                        ForEach(AppTheme.palette, id: \.self) { hex in
                            Button {
                                colorHex = hex
                            } label: {
                                Circle()
                                    .fill(Color(hex: hex))
                                    .frame(width: 30, height: 30)
                                    .overlay {
                                        if colorHex == hex {
                                            Circle().strokeBorder(.primary, lineWidth: 2).padding(-3)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                Section("Type") {
                    Picker("Type", selection: $type) {
                        ForEach(HabitType.allCases, id: \.self) { value in
                            Text(value.displayName).tag(value)
                        }
                    }
                    .pickerStyle(.segmented)
                    if type == .counter || type == .timer {
                        Stepper(value: $targetValue, in: 1...10000, step: type == .timer ? 5 : 1) {
                            Text("Daily target: \(Int(targetValue)) \(type == .timer ? "min" : unitLabel.isEmpty ? "times" : unitLabel)")
                        }
                    }
                    if type == .negative {
                        Stepper(value: $targetValue, in: 1...1000, step: 1) {
                            Text("Daily limit: \(Int(targetValue))")
                        }
                        Text("A limit habit tracks something you want to keep under a cap, like screen time or snacks.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Section("Schedule") {
                    Picker("Repeats", selection: $scheduleType) {
                        ForEach(HabitScheduleType.allCases, id: \.self) { value in
                            Text(value.displayName).tag(value)
                        }
                    }
                    if scheduleType == .weekdays {
                        HStack {
                            ForEach(1...7, id: \.self) { weekday in
                                Button {
                                    if selectedWeekdays.contains(weekday) {
                                        selectedWeekdays.remove(weekday)
                                    } else {
                                        selectedWeekdays.insert(weekday)
                                    }
                                } label: {
                                    Text(Self.weekdaySymbol(weekday))
                                        .font(AppTheme.pixelCaption)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(selectedWeekdays.contains(weekday) ? AppTheme.accent.opacity(0.2) : .clear)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    if scheduleType == .everyNDays {
                        Stepper(value: $everyNDays, in: 2...30) {
                            Text("Every \(everyNDays) days")
                        }
                    }
                    if scheduleType == .daysPerWeek {
                        Stepper(value: $daysPerWeek, in: 1...7) {
                            Text("\(daysPerWeek) times a week")
                        }
                    }
                }
                Section("Reminder") {
                    Toggle("Daily reminder", isOn: $reminderEnabled)
                    if reminderEnabled {
                        DatePicker("Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                    }
                }
                if habit != nil {
                    Section {
                        Button("Delete habit", role: .destructive) {
                            showDeleteConfirm = true
                        }
                    }
                }
            }
            .navigationTitle(habit == nil ? "New habit" : "Edit habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .disabled(name.isEmpty)
                }
            }
            .confirmationDialog("Delete this habit and all its pixels?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                Button("Delete", role: .destructive) { deleteHabit() }
                Button("Cancel", role: .cancel) {}
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        guard let habit else { return }
        name = habit.name
        iconSymbol = habit.iconSymbol
        colorHex = habit.colorHex
        type = habit.type
        targetValue = habit.targetValue
        unitLabel = habit.unitLabel
        scheduleType = habit.schedule.type
        if scheduleType == .weekdays {
            selectedWeekdays = habit.schedule.weekdays
        }
        if scheduleType == .everyNDays {
            everyNDays = max(2, habit.schedule.n)
        }
        if scheduleType == .daysPerWeek {
            daysPerWeek = max(1, habit.schedule.n)
        }
        reminderEnabled = habit.reminderEnabled
        reminderTime = Date.from(hour: habit.reminderHour, minute: habit.reminderMinute)
    }

    private func save() {
        let schedule: HabitSchedule
        switch scheduleType {
        case .daily: schedule = .daily
        case .weekdays: schedule = HabitSchedule(type: .weekdays, payload: selectedWeekdays.map(String.init).sorted().joined(separator: ","))
        case .everyNDays: schedule = HabitSchedule(type: .everyNDays, payload: String(everyNDays))
        case .daysPerWeek: schedule = HabitSchedule(type: .daysPerWeek, payload: String(daysPerWeek))
        }
        let components = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)

        if let habit {
            habit.name = name
            habit.iconSymbol = iconSymbol
            habit.colorHex = colorHex
            habit.type = type
            habit.targetValue = targetValue
            habit.unitLabel = unitLabel
            habit.schedule = schedule
            habit.reminderEnabled = reminderEnabled
            habit.reminderHour = components.hour ?? 9
            habit.reminderMinute = components.minute ?? 0
            ReminderScheduler.schedule(habit: habit)
        } else {
            let newHabit = Habit(name: name, iconSymbol: iconSymbol, colorHex: colorHex, type: type,
                                 schedule: schedule, targetValue: targetValue, unitLabel: unitLabel)
            newHabit.reminderEnabled = reminderEnabled
            newHabit.reminderHour = components.hour ?? 9
            newHabit.reminderMinute = components.minute ?? 0
            newHabit.sortOrder = checkIns.allHabits().count
            checkIns.persistence.context.insert(newHabit)
            try? checkIns.persistence.context.save()
            if reminderEnabled {
                ReminderScheduler.schedule(habit: newHabit)
            }
        }
        try? checkIns.persistence.context.save()
        SnapshotBuilder.rebuild(context: checkIns.persistence.context, settings: AppSettings.shared)
        dismiss()
    }

    private func deleteHabit() {
        guard let habit else { return }
        ReminderScheduler.schedule(habit: habit)
        habit.reminderEnabled = false
        ReminderScheduler.schedule(habit: habit)
        checkIns.persistence.context.delete(habit)
        try? checkIns.persistence.context.save()
        SnapshotBuilder.rebuild(context: checkIns.persistence.context, settings: AppSettings.shared)
        dismiss()
    }

    private static func weekdaySymbol(_ weekday: Int) -> String {
        let symbols = ["S", "M", "T", "W", "T", "F", "S"]
        return symbols[weekday - 1]
    }
}

extension Date {
    static func from(hour: Int, minute: Int) -> Date {
        Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: .now) ?? .now
    }
}
