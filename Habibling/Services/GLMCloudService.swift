import Foundation

enum GLMCloudError: LocalizedError {
    case rateLimited
    case invalidCredential
    case server(Int)
    case emptyResponse

    var errorDescription: String? {
        switch self {
        case .rateLimited:
            return "You're going fast! AI requests are limited to 30 per hour and 200 per day. Take a breather and try again soon."
        case .invalidCredential:
            return "Your Cloud+ subscription isn't active. Restore purchases in Settings to continue."
        case .server(let code):
            return "The AI service returned an error (code \(code)). Please try again later."
        case .emptyResponse:
            return "The AI returned an empty answer. Try rephrasing your request."
        }
    }
}

final class GLMCloudService {
    static let shared = GLMCloudService()
    static let appId = "habibling"

    private let primaryURL = URL(string: "https://cramjam-api.calcs.top")!
    private let fallbackURL = URL(string: "https://cramjam-proxy.iocompile67692.workers.dev")!

    func complete(messages: [[String: Any]], maxTokens: Int = 4096, jsonOutput: Bool = false) async throws -> String {
        do {
            return try await send(to: primaryURL, messages: messages, maxTokens: maxTokens, jsonOutput: jsonOutput)
        } catch let error as GLMCloudError {
            throw error
        } catch {
            return try await send(to: fallbackURL, messages: messages, maxTokens: maxTokens, jsonOutput: jsonOutput)
        }
    }

    private func send(to url: URL, messages: [[String: Any]], maxTokens: Int, jsonOutput: Bool) async throws -> String {
        var payload: [String: Any] = [
            "model": "glm-5.3-flash",
            "messages": messages,
            "thinking": ["level": "low"],
            "max_tokens": maxTokens,
            "temperature": 0.3
        ]
        if jsonOutput {
            payload["response_format"] = ["type": "json_object"]
        }
        var body: [String: Any] = [
            "appId": Self.appId,
            "userId": KeychainStore.userId(),
            "payload": payload
        ]
        #if DEBUG
        body["devKey"] = "cramjam-dev-2026"
        #endif
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 90
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard status == 200 else {
            switch status {
            case 429: throw GLMCloudError.rateLimited
            case 401: throw GLMCloudError.invalidCredential
            default: throw GLMCloudError.server(status)
            }
        }
        struct GLMResponse: Decodable {
            struct Choice: Decodable {
                struct Message: Decodable { let content: String? }
                let message: Message
            }
            let choices: [Choice]
        }
        let decoded = try JSONDecoder().decode(GLMResponse.self, from: data)
        guard let content = decoded.choices.first?.message.content, !content.isEmpty else {
            throw GLMCloudError.emptyResponse
        }
        return content
    }
}
