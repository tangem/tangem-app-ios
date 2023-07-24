//
//  WalletConnectSessionsStorage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Combine

protocol WalletConnectSessionsStorage: WalletConnectSessionsStorageCleaner {
    var sessions: AsyncStream<[WalletConnectSavedSession]> { get async }
    func restoreAllSessions()
    func save(_ session: WalletConnectSavedSession)
    func session(with id: Int) -> WalletConnectSavedSession?
    func session(with topic: String) -> WalletConnectSavedSession?
    func remove(_ session: WalletConnectSavedSession)
    func removeSessions(for userWalletId: String) -> [WalletConnectSavedSession]
}

protocol WalletConnectSessionsStorageCleaner: Actor {
    func clearStorage(for userWalletId: String)
}

private struct WalletConnectSessionsStorageKey: InjectionKey {
    static var currentValue: WalletConnectSessionsStorage = CommonWalletConnectSessionsStorage()
}

extension InjectedValues {
    var walletConnectSessionsStorage: WalletConnectSessionsStorage {
        get { Self[WalletConnectSessionsStorageKey.self] }
        set { Self[WalletConnectSessionsStorageKey.self] = newValue }
    }

    var walletConnectSessionsStorageCleaner: WalletConnectSessionsStorageCleaner { Self[WalletConnectSessionsStorageKey.self] }
}

actor CommonWalletConnectSessionsStorage {
    @Injected(\.persistentStorage) private var storage: PersistentStorageProtocol
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    var sessions: AsyncStream<[WalletConnectSavedSession]> {
        get async {
            let currentUserWalletId = currentUserWalletId

            return await allSessions
                .map { newSessions in
                    newSessions.filter { $0.userWalletId == currentUserWalletId }
                }
                .removeDuplicates()
                .values
        }
    }

    private let allSessions: CurrentValueSubject<[WalletConnectSavedSession], Never> = .init([])
    private var sessionsFilteringSubscription: AnyCancellable?

    private var currentUserWalletId: String? { userWalletRepository.selectedModel?.userWalletId.stringValue }

    func restoreAllSessions() {
        var savedSessions: [WalletConnectSavedSession] = (try? storage.value(for: .allWalletConnectSessions)) ?? []

        var shouldOverwriteAllSavedSessions = false
        for userWallet in userWalletRepository.models {
            // Migration from saving WC sessions by userWalletId to storing in single array of WC sessions
            if let oldSavedSessions: [WalletConnectSavedSession] = try? storage.value(for: .walletConnectSessions(userWalletId: userWallet.userWalletId.stringValue)) {
                savedSessions.append(contentsOf: oldSavedSessions)
                try? storage.store(value: [WalletConnectSavedSession]?(nil), for: .walletConnectSessions(userWalletId: userWallet.userWalletId.stringValue))
                shouldOverwriteAllSavedSessions = true
            }
        }

        allSessions.value = savedSessions

        if shouldOverwriteAllSavedSessions {
            saveSessionsToFile()
        }
    }

    private func readSessionsFromFile(with key: String) -> [WalletConnectSavedSession] {
        let savedSessions: [WalletConnectSavedSession] = (try? storage.value(for: .walletConnectSessions(userWalletId: key))) ?? []
        return savedSessions
    }

    private func saveSessionsToFile() {
        do {
            try storage.store(value: allSessions.value, for: .allWalletConnectSessions)
        } catch {
            AppLog.shared.error(error)
        }
    }
}

extension CommonWalletConnectSessionsStorage: WalletConnectSessionsStorage {
    func clearStorage(for userWalletId: String) {
        allSessions.value.removeAll()
        saveSessionsToFile()
    }

    func save(_ session: WalletConnectSavedSession) {
        allSessions.value.append(session)
        saveSessionsToFile()
    }

    func session(with id: Int) -> WalletConnectSavedSession? {
        return allSessions.value.first(where: { $0.id == id })
    }

    func session(with topic: String) -> WalletConnectSavedSession? {
        let session = allSessions.value.first(where: { $0.topic == topic })
        return session
    }

    func remove(_ session: WalletConnectSavedSession) {
        allSessions.value.remove(session)
        saveSessionsToFile()
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

        allSessions.value = sessions
        saveSessionsToFile()
        return removedSessions
    }
}
