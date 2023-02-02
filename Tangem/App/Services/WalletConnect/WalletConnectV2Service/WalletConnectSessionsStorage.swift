//
//  WalletConnectSessionsStorage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Combine

protocol WalletConnectSessionsStorage: Actor {
    var sessions: AsyncStream<[WalletConnectSavedSession]> { get async }
    @discardableResult
    func loadSessions(for userWalletId: String) -> [WalletConnectSavedSession]
    func save(_ session: WalletConnectSavedSession)
    func session(with id: Int) -> WalletConnectSavedSession?
    func session(with topic: String) -> WalletConnectSavedSession?
    func removeSession(with id: Int)
    func remove(_ session: WalletConnectSavedSession)
    func clearStorage()
}

private struct WalletConnectSessionsStorageKey: InjectionKey {
    static var currentValue: WalletConnectSessionsStorage = CommonWalletConnectSessionsStorage()
}

extension InjectedValues {
    var walletConnectSessionsStorage: WalletConnectSessionsStorage {
        get { Self[WalletConnectSessionsStorageKey.self] }
        set { Self[WalletConnectSessionsStorageKey.self] = newValue }
    }
}

actor CommonWalletConnectSessionsStorage {
    @Injected(\.persistentStorage) private var storage: PersistentStorageProtocol

    var sessions: AsyncStream<[WalletConnectSavedSession]> {
        get async {
            await $_sessions.values
        }
    }

    @Published private var _sessions: [WalletConnectSavedSession] = []

    private var currentUserWalletId: String?

    private func readSessionsFromFile(with key: String) -> [WalletConnectSavedSession] {
        let savedSessions: [WalletConnectSavedSession] = (try? storage.value(for: .walletConnectSessions(userWalletId: key))) ?? []
        return savedSessions
    }

    private func saveSessionsToFile() {
        guard let currentUserWalletId else { return }

        do {
            try storage.store(value: _sessions, for: .walletConnectSessions(userWalletId: currentUserWalletId))
        } catch {
            AppLog.shared.error(error)
        }
    }
}

extension CommonWalletConnectSessionsStorage: WalletConnectSessionsStorage {
    func clearStorage() {
        _sessions.removeAll()
        saveSessionsToFile()
    }

    func loadSessions(for userWalletId: String) -> [WalletConnectSavedSession] {
        currentUserWalletId = userWalletId
        let savedSessions = readSessionsFromFile(with: userWalletId)
        _sessions = savedSessions
        return savedSessions
    }

    func save(_ session: WalletConnectSavedSession) {
        _sessions.append(session)
        saveSessionsToFile()
    }

    func session(with id: Int) -> WalletConnectSavedSession? {
        return _sessions.first(where: { $0.id == id })
    }

    func session(with topic: String) -> WalletConnectSavedSession? {
        _sessions.first(where: { $0.topic == topic })
    }

    func removeSession(with id: Int) {
        guard let session = session(with: id) else { return }

        remove(session)
    }

    func remove(_ session: WalletConnectSavedSession) {
        _sessions.remove(session)
        saveSessionsToFile()
    }
}
