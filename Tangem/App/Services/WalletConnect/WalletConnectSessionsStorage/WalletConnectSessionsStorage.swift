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

    func loadSessions()
    func save(_ session: WalletConnectSavedSession)
    func session(with id: Int) -> WalletConnectSavedSession?
    func session(with topic: String) -> WalletConnectSavedSession?
    func remove(_ session: WalletConnectSavedSession)
    func removeSessions(for userWalletId: String) -> [WalletConnectSavedSession]
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
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    var sessions: AsyncStream<[WalletConnectSavedSession]> {
        get async {
            await allSessions.values
        }
    }

    private let allSessions: CurrentValueSubject<[WalletConnectSavedSession], Never> = .init([])
    private var sessionsFilteringSubscription: AnyCancellable?

    func loadSessions() {
        let savedSessions: [WalletConnectSavedSession] = (try? storage.value(for: .allWalletConnectSessions)) ?? []
        allSessions.value = savedSessions
    }

    private func saveCachedSessions() {
        saveSessionsToFile(allSessions.value)
    }

    private func saveSessionsToFile(_ sessions: [WalletConnectSavedSession]) {
        do {
            try storage.store(value: sessions, for: .allWalletConnectSessions)
        } catch {
            log("Failed to save session file to disk. Error: \(error)")
        }
    }

    private func log<T>(_ message: @autoclosure () -> T) {
        AppLog.shared.debug("[WC Sessions Storage] - \(message())")
    }
}

extension CommonWalletConnectSessionsStorage: WalletConnectSessionsStorage {
    func save(_ session: WalletConnectSavedSession) {
        allSessions.value.append(session)
        saveCachedSessions()
        log("Session with topic: \(session.topic) saved to disk.\nSession URL: \(session.sessionInfo.dAppInfo.url)")
    }

    func session(with id: Int) -> WalletConnectSavedSession? {
        return allSessions.value.first(where: { $0.id == id })
    }

    func session(with topic: String) -> WalletConnectSavedSession? {
        return allSessions.value.first(where: { $0.topic == topic })
    }

    func remove(_ session: WalletConnectSavedSession) {
        allSessions.value.remove(session)
        saveCachedSessions()
        log("Session with topic: \(session.topic) was removed from storage.\nSession URL: \(session.sessionInfo.dAppInfo.url)")
    }

    func removeSessions(for userWalletId: String) -> [WalletConnectSavedSession] {
        var sessions = allSessions.value
        var removedSessions = [WalletConnectSavedSession]()
        var indexiesToRemove = [Int]()
        for i in stride(from: sessions.endIndex - 1, through: 0, by: -1) {
            let session = sessions[i]
            if session.userWalletId.caseInsensitiveCompare(userWalletId) == .orderedSame {
                indexiesToRemove.append(i)
                removedSessions.append(session)
            }
        }

        indexiesToRemove.forEach {
            sessions.remove(at: $0)
        }

        if removedSessions.isEmpty {
            return []
        }

        saveSessionsToFile(sessions)
        allSessions.value = sessions
        log("All sessions for \(userWalletId) was removed. Number of removed sessions: \(removedSessions.count)")
        return removedSessions
    }
}
