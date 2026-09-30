import Foundation
import StoreKit

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
    /// Must exactly match the appId registered in the Worker's D1 `apps` whitelist
    /// (the Worker validates the appId ↔ bundleId binding during JWS verification).
    static let appId = "habibling"

    private let primaryURL = URL(string: "https://cramjam-api.calcs.top")!
    private let fallbackURL = URL(string: "https://cramjam-proxy.iocompile67692.workers.dev")!

    /// Dev channel key, loaded from GLMProxySecret.txt at the app root (gitignored,
    /// never committed). Release archives don't contain the file, so production
    /// builds automatically use the App Store JWS channel instead.
    private static var proxyDevKey: String? {
        guard let url = Bundle.main.url(forResource: "GLMProxySecret", withExtension: "txt"),
              let raw = try? String(contentsOf: url, encoding: .utf8) else { return nil }
        let key = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return key.isEmpty ? nil : key
    }

    func complete(messages: [[String: Any]], maxTokens: Int = 4096, jsonOutput: Bool = false) async throws -> String {
        // GLM-5.3-Flash: thinking cannot be disabled (error 1210) — always send a level.
        // Reasoning tokens count against the completion budget: text >=4096, structured >=8192,
        // otherwise `content` comes back empty with finish_reason "length".
        let budget = jsonOutput ? max(maxTokens, 8192) : maxTokens
        var payload: [String: Any] = [
            "model": "glm-5.3-flash",
            "messages": messages,
            "thinking": ["level": "low"],
            "max_tokens": budget,
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
        // Channel priority: App Store JWS (production + sandbox/TestFlight) -> devKey
        // file (development only) -> error guiding the user to restore purchases.
        if let jws = await Self.currentEntitlementJWS() {
            body["appTransaction"] = jws
        } else if let devKey = Self.proxyDevKey {
            body["devKey"] = devKey
        } else {
            throw GLMCloudError.invalidCredential
        }
        do {
            return try await send(to: primaryURL, body: body)
        } catch let error as GLMCloudError {
            switch error {
            case .rateLimited, .invalidCredential:
                // Authoritative responses — retrying the backup line won't change the outcome.
                throw error
            case .server, .emptyResponse:
                return try await send(to: fallbackURL, body: body)
            }
        } catch {
            // Network failure (timeout, no connection, TLS) -> backup line.
            return try await send(to: fallbackURL, body: body)
        }
    }

    private func send(to url: URL, body: [String: Any]) async throws -> String {
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

    /// Returns the JWS of the user's current entitlement (Cloud+ subscription or Plus lifetime).
    /// nil = no valid entitlement; callers should guide the user to restore purchases.
    static func currentEntitlementJWS() async -> String? {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                guard transaction.revocationDate == nil else { continue }
                if transaction.productType == .autoRenewable || transaction.productType == .nonConsumable {
                    // Must use result.jwsRepresentation (signed "header.payload.signature").
                    // transaction.jsonRepresentation is the DECODED payload only — unsigned,
                    // and the server-side signature verification would reject it.
                    return result.jwsRepresentation
                }
            }
        }
        return nil
    }
}
