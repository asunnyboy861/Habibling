import SwiftUI

struct PetView: View {
    @EnvironmentObject private var checkIns: CheckInService
    @EnvironmentObject private var settings: AppSettings

    @State private var petState = PetState(stage: .egg, mood: .content, season: .spring, progression: 0, daysKept: 0)
    @State private var showRename = false
    @State private var newName = ""
    @State private var encouragement = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    petCard
                    dexCard
                    seasonCard
                    encouragementCard
                }
                .padding(16)
            }
            .background(AppTheme.page)
            .navigationTitle("Pet")
        }
        .onAppear(perform: reload)
    }

    private var petCard: some View {
        VStack(spacing: 14) {
            PixelPetView(stage: petState.stage, mood: petState.mood)
                .frame(width: 180, height: 180)
                .padding(.top, 8)
            HStack(spacing: 8) {
                Text(settings.petName)
                    .font(.system(.title2, design: .monospaced))
                    .fontWeight(.bold)
                Button {
                    newName = settings.petName
                    showRename = true
                } label: {
                    Image(systemName: "pencil.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            Text(petState.stage.displayName)
                .font(AppTheme.pixelCaption)
                .fontWeight(.semibold)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(AppTheme.accent.opacity(0.16))
                .clipShape(Capsule())
            ProgressView(value: petState.progression)
                .tint(AppTheme.accent)
                .padding(.horizontal, 32)
            Text("\(petState.daysKept) pixels earned  ·  \(AppTheme.stageProgressText(petState))")
                .font(AppTheme.pixelCaption)
                .foregroundStyle(.secondary)
            moodChip
        }
        .frame(maxWidth: .infinity)
        .pixelCard()
        .alert("Rename your pet", isPresented: $showRename) {
            TextField("Name", text: $newName)
            Button("Save") {
                if !newName.isEmpty {
                    settings.petName = newName
                    SnapshotBuilder.rebuild(context: checkIns.persistence.context, settings: settings)
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var moodChip: some View {
        HStack(spacing: 6) {
            Image(systemName: petState.mood == .joyful ? "face.smiling.inverse" : petState.mood == .content ? "face.smiling" : "moon.zzz")
            Text(petState.mood == .joyful ? "Joyful — strong week" : petState.mood == .content ? "Content — steady week" : "Sleepy — resting is okay")
                .font(AppTheme.pixelCaption)
        }
        .foregroundStyle(.secondary)
    }

    private var dexCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Evolution line")
                .font(AppTheme.pixelTitle)
            HStack(spacing: 10) {
                ForEach(PetStage.allCases, id: \.self) { stage in
                    let unlocked = petState.daysKept >= Self.threshold(for: stage)
                    VStack(spacing: 6) {
                        PixelPetView(stage: stage, mood: unlocked ? .joyful : .sleepy, animated: false)
                            .frame(width: 52, height: 52)
                            .opacity(unlocked ? 1 : 0.3)
                        Text(stage.displayName)
                            .font(AppTheme.pixelCaption)
                            .foregroundStyle(unlocked ? .primary : .secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(unlocked ? AppTheme.accent.opacity(0.1) : AppTheme.page)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .pixelCard()
    }

    private var seasonCard: some View {
        HStack(spacing: 12) {
            Image(systemName: AppTheme.seasonSymbol)
                .font(.title2)
                .foregroundStyle(Color(hex: petState.season.accentHex))
            VStack(alignment: .leading, spacing: 2) {
                Text("\(petState.season.rawValue.capitalized) pet")
                    .font(AppTheme.pixelTitle)
                Text("Your pet wears seasonal colors. December brings a holiday coat.")
                    .font(AppTheme.pixelCaption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .pixelCard()
    }

    private var encouragementCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Pet says")
                    .font(AppTheme.pixelTitle)
                Spacer()
                Button {
                    Task {
                        let summary = AICoachService.Summary(dueCount: max(petState.daysKept, 1), doneCount: petState.daysKept)
                        encouragement = await AICoachService.shared.encouragement(summary: summary)
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.plain)
            }
            Text(encouragement.isEmpty ? "Tap refresh — your pet has something to say." : encouragement)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .pixelCard()
    }

    private static func threshold(for stage: PetStage) -> Int {
        switch stage {
        case .egg: 0
        case .hatchling: 3
        case .juvenile: 14
        case .adult: 30
        }
    }

    private func reload() {
        petState = checkIns.currentPetState()
        if encouragement.isEmpty {
            Task {
                let summary = AICoachService.Summary(dueCount: max(petState.daysKept, 1), doneCount: petState.daysKept)
                encouragement = await AICoachService.shared.encouragement(summary: summary)
            }
        }
    }
}
