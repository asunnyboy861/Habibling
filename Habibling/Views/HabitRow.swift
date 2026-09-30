import SwiftUI

struct HabitRow: View {
    var habit: Habit
    var currentValue: Double
    var onToggle: () -> Void
    var onIncrement: () -> Void
    var onDecrement: () -> Void
    var onLog: () -> Void
    var onNote: () -> Void

    private var progress: Double {
        if habit.type == .negative {
            guard currentValue > 0 else { return 0 }
            return max(0, 1 - currentValue / max(habit.targetValue, 0.0001))
        }
        return min(1, currentValue / max(habit.targetValue, 0.0001))
    }

    private var isDone: Bool {
        habit.type == .negative ? currentValue > 0 && currentValue <= habit.targetValue : currentValue >= habit.targetValue
    }

    private var valueText: String {
        switch habit.type {
        case .binary: isDone ? "Done" : "Tap to complete"
        case .counter, .timer: "\(Int(currentValue)) of \(Int(habit.targetValue)) \(habit.unitLabel)"
        case .negative: isDone ? "Under limit" : "\(Int(currentValue)) of \(Int(habit.targetValue)) max"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: habit.iconSymbol)
                    .font(.title3)
                    .foregroundStyle(Color(hex: habit.colorHex))
                    .frame(width: 40, height: 40)
                    .background(Color(hex: habit.colorHex).opacity(0.14))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                VStack(alignment: .leading, spacing: 2) {
                    Text(habit.name)
                        .font(AppTheme.pixelTitle)
                        .strikethrough(isDone && habit.type != .negative)
                    Text(habit.schedule.summary)
                        .font(AppTheme.pixelCaption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                controls
            }
            ProgressView(value: progress)
                .tint(Color(hex: habit.colorHex))
            HStack {
                Text(valueText)
                    .font(AppTheme.pixelCaption)
                    .foregroundStyle(.secondary)
                Spacer()
                Menu {
                    Button(action: onLog) { Label("Log value", systemImage: "slider.horizontal.3") }
                    Button(action: onNote) { Label("Add note", systemImage: "square.and.pencil") }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(width: 32, height: 32)
                }
            }
        }
        .pixelCard()
    }

    @ViewBuilder
    private var controls: some View {
        switch habit.type {
        case .binary:
            Button(action: onToggle) {
                Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 32))
                    .foregroundStyle(isDone ? Color(hex: habit.colorHex) : Color(.systemGray4))
            }
            .buttonStyle(.plain)
        case .counter, .timer:
            HStack(spacing: 8) {
                Button(action: onDecrement) {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                Button(action: onIncrement) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color(hex: habit.colorHex))
                }
                .buttonStyle(.plain)
                Button(action: onToggle) {
                    Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 28))
                        .foregroundStyle(isDone ? Color(hex: habit.colorHex) : Color(.systemGray4))
                }
                .buttonStyle(.plain)
            }
        case .negative:
            HStack(spacing: 8) {
                Button(action: onIncrement) {
                    Text("+1 used")
                        .font(AppTheme.pixelCaption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(.systemGray5))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                Button(action: onToggle) {
                    Text("Clean day")
                        .font(AppTheme.pixelCaption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(isDone ? Color(hex: habit.colorHex).opacity(0.2) : Color(.systemGray5))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct ValueLogSheet: View {
    var habit: Habit
    var onSave: (Double) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var value: Double = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Log \(habit.name)")
                    .font(AppTheme.pixelTitle)
                Stepper(value: $value, in: 0...10000, step: max(1, habit.targetValue / 4)) {
                    Text("\(Int(value)) \(habit.unitLabel)")
                        .font(.system(.largeTitle, design: .monospaced))
                        .fontWeight(.bold)
                }
                .padding(.horizontal, 32)
                Button("Save") {
                    onSave(value)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                Spacer()
            }
            .padding(.top, 32)
            .navigationTitle("Log value")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
        .onAppear {
            value = habit.targetValue
        }
    }
}

struct NoteSheet: View {
    var habit: Habit
    var checkIns: CheckInService

    @Environment(\.dismiss) private var dismiss
    @State private var note = ""
    @StateObject private var speech = SpeechService()

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                TextEditor(text: $note)
                    .frame(minHeight: 120)
                    .padding(8)
                    .background(AppTheme.page)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                if speech.isRecording {
                    Text(speech.transcript.isEmpty ? "Listening..." : speech.transcript)
                        .font(AppTheme.pixelCaption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                }
                Button {
                    if speech.isRecording {
                        speech.stop()
                        if !speech.transcript.isEmpty {
                            note = note.isEmpty ? speech.transcript : note + " " + speech.transcript
                        }
                    } else {
                        Task {
                            if await SpeechService.requestPermissions() {
                                speech.start()
                            }
                        }
                    }
                } label: {
                    Label(speech.isRecording ? "Stop" : "Dictate", systemImage: speech.isRecording ? "stop.circle.fill" : "mic.circle")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.bordered)
                .padding(.horizontal)
                Spacer()
            }
            .navigationTitle("Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        speech.stop()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        speech.stop()
                        let bucket = DayBucket.startOfDay(for: .now)
                        let existing = checkIns.completions(for: habit).first {
                            Calendar.current.isDate($0.dayBucket, inSameDayAs: bucket)
                        }
                        if let existing {
                            existing.note = note
                            try? checkIns.persistence.context.save()
                        } else {
                            let completion = Completion(habitPersistentID: habit.persistentID,
                                                        dayBucket: bucket,
                                                        value: 0,
                                                        source: .manual,
                                                        note: note)
                            completion.habit = habit
                            checkIns.persistence.context.insert(completion)
                            try? checkIns.persistence.context.save()
                        }
                        dismiss()
                    }
                    .disabled(note.isEmpty && speech.transcript.isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

enum EvolutionCelebration {
    static func show(stage: PetStage, petName: String) {
        guard let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first,
              let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController else { return }
        let overlay = EvolutionOverlayController(stage: stage, petName: petName)
        root.present(overlay, animated: false)
    }
}

final class EvolutionOverlayController: UIViewController {
    private let stage: PetStage
    private let petName: String

    init(stage: PetStage, petName: String) {
        self.stage = stage
        self.petName = petName
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.55)
        let host = UIHostingController(rootView: EvolutionOverlayContent(stage: stage, petName: petName) { [weak self] in
            self?.dismiss(animated: true)
        })
        host.view.backgroundColor = .clear
        addChild(host)
        view.addSubview(host.view)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            host.view.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            host.view.heightAnchor.constraint(equalToConstant: 340)
        ])
        host.didMove(toParent: self)
    }
}

struct EvolutionOverlayContent: View {
    var stage: PetStage
    var petName: String
    var onClose: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("\(petName) evolved!")
                .font(.system(.title2, design: .monospaced))
                .fontWeight(.bold)
                .foregroundStyle(.white)
            PixelPetView(stage: stage, mood: .joyful)
                .frame(width: 150, height: 150)
                .padding(20)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 24))
            Text("Stage: \(stage.displayName)")
                .font(AppTheme.pixelTitle)
                .foregroundStyle(.white)
            Button("Keep going") {
                onClose()
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 4)
        }
        .padding(28)
    }
}
