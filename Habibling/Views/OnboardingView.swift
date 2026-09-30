import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var checkIns: CheckInService
    @EnvironmentObject private var purchases: PurchaseManager

    @State private var step = 0
    @State private var petName = "Momo"
    @State private var habitName = "Drink water"
    @State private var habitIcon = "drop"
    @State private var habitColor = "#4FB8D9"
    @State private var habitTarget = 8.0

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $step) {
                welcomeStep.tag(0)
                nameStep.tag(1)
                habitStep.tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            Button(action: advance) {
                Text(step == 2 ? "Start growing" : "Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .background(AppTheme.page)
    }

    private var welcomeStep: some View {
        VStack(spacing: 24) {
            Spacer()
            PixelPetView(stage: .hatchling, mood: .joyful)
                .frame(width: 160, height: 160)
            Text("Habibling")
                .font(.system(.largeTitle, design: .monospaced))
                .fontWeight(.bold)
            Text("Your habits hatch a tiny pixel pet.\nMiss a day? It naps — never dies.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Spacer()
            Spacer()
        }
        .padding(24)
    }

    private var nameStep: some View {
        VStack(spacing: 24) {
            Spacer()
            PixelPetView(stage: .egg, mood: .content)
                .frame(width: 140, height: 140)
            Text("Name your pet")
                .font(.system(.title2, design: .monospaced))
                .fontWeight(.bold)
            Text("Every pixel you earn feeds it.")
                .foregroundStyle(.secondary)
            TextField("Pet name", text: $petName)
                .textFieldStyle(.roundedBorder)
                .font(.title3)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 48)
            Spacer()
            Spacer()
        }
        .padding(24)
    }

    private var habitStep: some View {
        VStack(spacing: 20) {
            Spacer()
            Text("Pick a first habit")
                .font(.system(.title2, design: .monospaced))
                .fontWeight(.bold)
            Text("You can add more anytime. Free plans have no habit limit.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 32)
            TextField("Habit name", text: $habitName)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 48)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                ForEach(AppTheme.iconChoices.prefix(8), id: \.self) { icon in
                    Button {
                        habitIcon = icon
                        habitColor = AppTheme.palette[AppTheme.iconChoices.firstIndex(of: icon) ?? 0]
                    } label: {
                        Image(systemName: icon)
                            .font(.title3)
                            .frame(width: 52, height: 52)
                            .background(habitIcon == icon ? Color(hex: habitColor).opacity(0.25) : AppTheme.card)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 32)

            Stepper(value: $habitTarget, in: 1...20, step: 1) {
                Text("Goal: \(Int(habitTarget)) per day")
                    .font(AppTheme.pixelTitle)
            }
            .padding(.horizontal, 48)
            Spacer()
            Spacer()
        }
        .padding(24)
    }

    private func advance() {
        if step < 2 {
            step += 1
            return
        }
        settings.petName = petName.isEmpty ? "Momo" : petName
        settings.petCreatedAt = .now
        settings.lastShownStage = 0
        let habit = Habit(name: habitName.isEmpty ? "Drink water" : habitName,
                          iconSymbol: habitIcon,
                          colorHex: habitColor,
                          type: .counter,
                          schedule: .daily,
                          targetValue: habitTarget,
                          unitLabel: "glasses")
        checkIns.persistence.context.insert(habit)
        try? checkIns.persistence.context.save()
        ReminderScheduler.schedule(habit: habit)
        SnapshotBuilder.rebuild(context: checkIns.persistence.context, settings: settings)
        Task { await ReminderScheduler.requestPermission() }
        settings.onboardingCompleted = true
    }
}
