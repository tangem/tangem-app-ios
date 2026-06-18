//
//  SupportChatTokenStorage.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

/// Persists the Usedesk chat token (`usedesk_messenger_token` value) in the Keychain.
///
/// The token is passed to `usedeskMessenger.userIdentify({ token: ... })` on the next open
/// so Usedesk resumes the same client/chat. It's kept on a 7-day sliding window: every chat
/// open refreshes the timestamp, and a token untouched for longer is dropped.
struct SupportChatTokenStorage {
    private let secureStorage = SecureStorage()

    /// Returns the stored token if still within the validity window, refreshing its
    /// timestamp (sliding window). Expired tokens are deleted and `nil` is returned.
    func loadValidToken() -> String? {
        do {
            guard let data = try secureStorage.get(Constants.key) else { return nil }
            let entry = try JSONDecoder().decode(Entry.self, from: data)

            guard Date().timeIntervalSince(entry.lastAccess) <= Constants.lifetime else {
                clear()
                return nil
            }

            save(token: entry.token)
            return entry.token
        } catch {
            SupportChatLogger.error(error: error)
            return nil
        }
    }

    func save(token: String) {
        do {
            let entry = Entry(token: token, lastAccess: Date())
            let data = try JSONEncoder().encode(entry)
            try secureStorage.store(data, forKey: Constants.key)
        } catch {
            SupportChatLogger.error(error: error)
        }
    }

    func clear() {
        do {
            try secureStorage.delete(Constants.key)
        } catch {
            SupportChatLogger.error(error: error)
        }
    }
}

private extension SupportChatTokenStorage {
    struct Entry: Codable {
        let token: String
        let lastAccess: Date
    }

    enum Constants {
        static let key = "support_chat_usedesk_token"
        static let lifetime: TimeInterval = 7 * 24 * 60 * 60
    }
}
