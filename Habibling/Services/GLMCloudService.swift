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
        // GLM-5.3-Flash: thinking cannot be disabled; structured output needs a generous completion budget.
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
        #if DEBUG
        // Test channel only (Worker DEV_MODE). Production sends an Apple-signed JWS instead.
        body["devKey"] = "cramjam-dev-2026"
        #else
        // Production: pass the App Store-signed transaction JWS (Cloud+ subscription or Plus).
        // The Worker verifies the ES256 signature, cert chain, bundleId whitelist, refund status,
        // and expiry; it accepts both Production and Sandbox receipts (TestFlight + review).
        guard let jws = await Self.currentEntitlementJWS() else {
            throw GLMCloudError.invalidCredential
        }
        body["appTransaction"] = jws
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

    /// Returns the JWS of the user's current entitlement (Cloud+ subscription or Plus lifetime).
    /// nil = no valid entitlement; callers should guide the user to restore purchases.
    static func currentEntitlementJWS() async -> String? {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.productType == .autoRenewable || transaction.productType == .nonConsumable {
                    // Transaction.jsonRepresentation is the signed JWS (header.payload.signature).
                    return String(data: transaction.jsonRepresentation, encoding: .utf8)
                }
            }
        }
        return nil
    }
}
