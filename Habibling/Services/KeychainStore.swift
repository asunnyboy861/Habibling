import Foundation
import Security

enum KeychainStore {
    static let service = "com.zzoutuo.Habibling"

    static func userId() -> String {
        let account = "deviceUserId"
        if let existing = readString(account: account), !existing.isEmpty {
            return existing
        }
        let fresh = UUID().uuidString
        saveString(fresh, account: account)
        return fresh
    }

    static func save(_ data: Data, account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
        var attributes = query
        attributes[kSecValueData as String] = data
        SecItemAdd(attributes as CFDictionary, nil)
    }

    static func read(account: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        SecItemCopyMatching(query as CFDictionary, &result)
        return result as? Data
    }

    static func saveString(_ value: String, account: String) {
        guard let data = value.data(using: .utf8) else { return }
        save(data, account: account)
    }

    static func readString(account: String) -> String? {
        guard let data = read(account: account) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
