//
//  WalletConnectStorage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

protocol WalletConnectStorage {
    var savedSessions: [WalletConnectSession] { get }
    func saveNewSessionToDefaults(_ session: WalletConnectSession)
    func deleteSessionFromDefaults(_ session: WalletConnectSession)
    func updateSessionInDefaults(from oldSession: WalletConnectSession, to newSession: WalletConnectSession)
}

private struct WalletConnectStorageKey: InjectionKey {
    static var currentValue: WalletConnectStorage = CommonWalletConnectStorage()
}

extension InjectedValues {
    var walletConnectStorage: WalletConnectStorage {
        get { Self[WalletConnectStorageKey.self] }
        set { Self[WalletConnectStorageKey.self] = newValue }
    }
}

class CommonWalletConnectStorage: WalletConnectStorage {
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    private let userDefaults = UserDefaults.standard
    private let sessionsKey = "wc_sessions"

    var savedSessions: [WalletConnectSession] {
        guard
            let sessionsObject = userDefaults.object(forKey: self.sessionsKey) as? Data,
            let decodedSessions = try? decoder.decode([WalletConnectSession].self, from: sessionsObject)
        else {
            return []
        }

        return decodedSessions
    }

    func saveNewSessionToDefaults(_ session: WalletConnectSession) {
        var sessionsToSave = savedSessions
        if !sessionsToSave.contains(where: { $0.session == session.session }) {
            sessionsToSave.append(session)
            encodeSessionsToDefaults(sessionsToSave)
        }
    }

    func deleteSessionFromDefaults(_ session: WalletConnectSession) {
        var sessionsToSave = savedSessions
        if let index = sessionsToSave.firstIndex(where: { $0.session == session.session }) {
            sessionsToSave.remove(at: index)
            encodeSessionsToDefaults(sessionsToSave)
        }
    }

    func updateSessionInDefaults(from oldSession: WalletConnectSession, to newSession: WalletConnectSession) {
        var savedSessions = savedSessions
        if let index = savedSessions.firstIndex(where: { $0.session == oldSession.session }) {
            savedSessions[index] = newSession
            encodeSessionsToDefaults(savedSessions)
        }
    }

    private func encodeSessionsToDefaults(_ sessions: [WalletConnectSession]) {
        if let dataToSave = try? encoder.encode(sessions) {
            userDefaults.set(dataToSave, forKey: sessionsKey)
        }
    }
}
