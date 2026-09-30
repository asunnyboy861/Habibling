import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var checkIns: CheckInService
    @EnvironmentObject private var purchases: PurchaseManager

    @State private var showPaywall = false
    @State private var importURL: URL?
    @State private var showImporter = false
    @State private var importMessage: String?
    @State private var shareURL: URL?
    @State private var exportError: String?

    var body: some View {
        NavigationStack {
            Form {
                petSection
                purchaseSection
                dataSection
                supportSection
                legalSection
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $showImporter) {
                DocumentPicker(forContentTypes: [.json]) { url in
                    Task { await importBackup(from: url) }
                }
            }
            .sheet(item: Binding(get: { shareURL.map(URLOnly.init) }, set: { shareURL = $0?.url })) { holder in
                ShareSheet(items: [holder.url])
            }
        }
    }

    private var petSection: some View {
        Section("Pet") {
            HStack {
                Text("Name")
                Spacer()
                TextField("Name", text: $settings.petName)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 140)
                    .onChange(of: settings.petName) { _ in
                        SnapshotBuilder.rebuild(context: checkIns.persistence.context, settings: settings)
                    }
            }
            Picker("Theme", selection: Binding(get: { settings.accentTheme }, set: { settings.accentTheme = $0 })) {
                Text("Coral").tag("coral")
                Text("Mint").tag("mint")
                Text("Ocean").tag("ocean")
                Text("Lavender").tag("lavender")
                Text("Sunset").tag("sunset")
            }
            Picker("Day starts at", selection: dayStartHour) {
                ForEach(0..<6, id: \.self) { hour in
                    Text(hour == 0 ? "Midnight" : "\(hour):00 AM").tag(hour)
                }
            }
        }
    }

    private var dayStartHour: Binding<Int> {
        Binding(get: { DayBucket.dayStartHour },
                set: { newValue in
                    DayBucket.dayStartHour = newValue
                    SnapshotBuilder.rebuild(context: checkIns.persistence.context, settings: settings)
                })
    }

    private var purchaseSection: some View {
        Section("Purchases") {
            HStack {
                Label("Habibling Plus", systemImage: "crown.fill")
                Spacer()
                Text(purchases.isPlus ? "Owned" : "$24.99 lifetime")
                    .font(.subheadline)
                    .foregroundStyle(purchases.isPlus ? AppTheme.accent : .secondary)
            }
            HStack {
                Label("Cloud+ AI", systemImage: "cloud.fill")
                Spacer()
                Text(purchases.isCloudPlus ? "Active" : "$1.99/month")
                    .font(.subheadline)
                    .foregroundStyle(purchases.isCloudPlus ? AppTheme.accent : .secondary)
            }
            Button("Unlock with Plus or Cloud+") {
                showPaywall = true
            }
            Button("Restore purchases") {
                Task { await purchases.restorePurchases() }
            }
            if let loadError = purchases.loadError {
                Text(loadError)
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
    }

    private var dataSection: some View {
        Section {
            HStack {
                Label("iCloud sync", systemImage: "icloud")
                Spacer()
                Text(FileManager.default.ubiquityIdentityToken != nil ? "On" : "Off")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Button("Export backup (JSON)") {
                exportBackup()
            }
            Button("Export history (CSV)") {
                exportCSV()
            }
            Button("Import backup (JSON)") {
                showImporter = true
            }
            if let importMessage {
                Text(importMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if let exportError {
                Text(exportError)
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
            Text("Free plans sync everything through iCloud. Backups are a Plus feature for extra safety.")
                .font(.caption)
                .foregroundStyle(.secondary)
        } header: {
            Text("Data")
        } footer: {
            Text("Habibling Plus unlocks JSON/CSV backup import and export.")
        }
    }

    private var supportSection: some View {
        Section("Support") {
            NavigationLink {
                ContactSupportView()
            } label: {
                Label("Contact support", systemImage: "envelope")
            }
            HStack {
                Label("AI engine", systemImage: "sparkles")
                Spacer()
                Text(AICoachService.shared.currentEngine.rawValue)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var legalSection: some View {
        Section("Legal") {
            Link(destination: URL(string: "https://asunnyboy861.github.io/Habibling/privacy.html")!) {
                Label("Privacy Policy", systemImage: "hand.raised")
            }
            Link(destination: URL(string: "https://asunnyboy861.github.io/Habibling/terms.html")!) {
                Label("Terms of Use", systemImage: "doc.text")
            }
            HStack {
                Text("Version")
                Spacer()
                Text(appVersion)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    private func exportBackup() {
        guard purchases.isPlus else {
            showPaywall = true
            return
        }
        do {
            shareURL = try BackupService.exportJSON(context: checkIns.persistence.context)
            exportError = nil
        } catch {
            exportError = "Export failed: \(error.localizedDescription)"
        }
    }

    private func exportCSV() {
        guard purchases.isPlus else {
            showPaywall = true
            return
        }
        do {
            shareURL = try BackupService.exportCSV(context: checkIns.persistence.context)
            exportError = nil
        } catch {
            exportError = "Export failed: \(error.localizedDescription)"
        }
    }

    private func importBackup(from url: URL) async {
        guard purchases.isPlus else {
            showPaywall = true
            return
        }
        do {
            let secured = url.startAccessingSecurityScopedResource()
            defer { if secured { url.stopAccessingSecurityScopedResource() } }
            let imported = try await BackupService.importJSON(from: url, context: checkIns.persistence.context)
            importMessage = "Imported \(imported) check-ins."
        } catch {
            importMessage = "Import failed: \(error.localizedDescription)"
        }
    }
}

private struct URLOnly: Identifiable {
    let id = UUID()
    let url: URL
}

struct DocumentPicker: UIViewControllerRepresentable {
    var forContentTypes: [UTType]
    var onPick: (URL) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: forContentTypes, asCopy: true)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick)
    }

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: (URL) -> Void

        init(onPick: @escaping (URL) -> Void) {
            self.onPick = onPick
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            if let url = urls.first {
                onPick(url)
            }
        }
    }
}
