import SwiftUI

struct ContactSupportView: View {
    @Environment(\.dismiss) private var dismiss

    enum Subject: String, CaseIterable, Identifiable {
        case bug = "Report a bug"
        case feature = "Feature request"
        case purchase = "Purchase & billing"
        case dataSync = "Data & iCloud sync"
        case widgets = "Widgets & Watch"
        case ai = "AI features"
        case other = "Something else"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .bug: "ladybug"
            case .feature: "lightbulb"
            case .purchase: "creditcard"
            case .dataSync: "icloud"
            case .widgets: "square.grid.2x2"
            case .ai: "sparkles"
            case .other: "questionmark.circle"
            }
        }
    }

    @State private var selectedSubject: Subject?
    @State private var name = ""
    @State private var email = ""
    @State private var message = ""
    @State private var includeDiagnostics = true
    @State private var isSending = false
    @State private var resultText: String?

    private var requiredFieldsFilled: Bool {
        selectedSubject != nil && !name.trimmingCharacters(in: .whitespaces).isEmpty
            && !email.trimmingCharacters(in: .whitespaces).isEmpty
            && message.trimmingCharacters(in: .whitespaces).count >= 5
    }

    var body: some View {
        Form {
            Section {
                ForEach(Subject.allCases) { subject in
                    Button {
                        selectedSubject = subject
                    } label: {
                        HStack {
                            Image(systemName: subject.icon)
                                .foregroundStyle(AppTheme.accent)
                                .frame(width: 26)
                            Text(subject.rawValue)
                                .foregroundStyle(.primary)
                            Spacer()
                            if selectedSubject == subject {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(AppTheme.accent)
                            }
                        }
                    }
                }
            } header: {
                Text("What is this about?")
            } footer: {
                Text("Pick a topic so we can route your message to the right place.")
            }

            Section("Your details") {
                TextField("Name", text: $name)
                    .textInputAutocapitalization(.words)
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }

            Section {
                TextEditor(text: $message)
                    .frame(minHeight: 110)
            } header: {
                Text("Message")
            } footer: {
                Text("Tell us what happened and what you expected. The more detail, the faster we can help.")
            }

            Section {
                Toggle("Attach device diagnostics", isOn: $includeDiagnostics)
                    .tint(AppTheme.accent)
                HStack {
                    Text("App version")
                    Spacer()
                    Text(appVersion).foregroundStyle(.secondary)
                }
                HStack {
                    Text("System")
                    Spacer()
                    Text(systemVersion).foregroundStyle(.secondary)
                }
            } footer: {
                Text("Diagnostics only include your device model and OS version. No habit data leaves your device unless you type it here.")
            }

            Section {
                Button {
                    send()
                } label: {
                    if isSending {
                        ProgressView().frame(maxWidth: .infinity)
                    } else {
                        Text("Send message").frame(maxWidth: .infinity)
                    }
                }
                .disabled(!requiredFieldsFilled || isSending)
                if let resultText {
                    Text(resultText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Link("Or email us directly", destination: mailtoURL)
                    .font(.subheadline)
            }
        }
        .navigationTitle("Contact support")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var mailtoURL: URL {
        let subject = "[Habibling] \(selectedSubject?.rawValue ?? "Support")"
        let body = message.isEmpty ? "" : "\n\n\(message)"
        return URL(string: "mailto:asunnyboy168@icloud.com?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&body=\(body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")!
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    private var systemVersion: String {
        "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion) · \(UIDevice.current.model)"
    }

    private func send() {
        isSending = true
        resultText = nil
        let payload: [String: Any] = [
            "app": "habibling",
            "subject": selectedSubject?.rawValue ?? "Other",
            "name": name.trimmingCharacters(in: .whitespaces),
            "email": email.trimmingCharacters(in: .whitespaces),
            "message": message.trimmingCharacters(in: .whitespaces),
            "appVersion": appVersion,
            "device": includeDiagnostics ? systemVersion : "",
            "userId": KeychainStore.userId()
        ]
        guard let url = URL(string: "https://msg.calcs.top/api/feedback"),
              let body = try? JSONSerialization.data(withJSONObject: payload) else {
            isSending = false
            resultText = "Could not prepare the request. Please use email instead."
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        Task {
            do {
                let (_, response) = try await URLSession.shared.data(for: request)
                let status = (response as? HTTPURLResponse)?.statusCode ?? 0
                await MainActor.run {
                    isSending = false
                    if (200..<300).contains(status) {
                        resultText = "Sent! We usually reply within 24 hours."
                        message = ""
                    } else {
                        resultText = "The server responded with \(status). Please use email instead."
                    }
                }
            } catch {
                await MainActor.run {
                    isSending = false
                    resultText = "Network error. Please use the email link below."
                }
            }
        }
    }
}
