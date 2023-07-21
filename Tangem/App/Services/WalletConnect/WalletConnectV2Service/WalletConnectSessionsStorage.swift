//
//  WalletConnectSessionsStorage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Combine
import CombineExt

protocol WalletConnectSessionsStorage: WalletConnectSessionsStorageCleaner {
    var sessions: AsyncStream<[WalletConnectSavedSession]> { get async }
    func restore
    @discardableResult
    func loadSessions(for userWalletId: String) -> [WalletConnectSavedSession]
    func save(_ session: WalletConnectSavedSession)
    func session(with id: Int) -> WalletConnectSavedSession?
    func session(with topic: String) -> WalletConnectSavedSession?
    func removeSession(with id: Int)
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

//    [REDACTED_USERNAME] private var _sessions: [WalletConnectSavedSession] = []

    private let allSessions: CurrentValueSubject<[WalletConnectSavedSession], Never> = .init([])
    private var sessionsFilteringSubscription: AnyCancellable?

    private var currentUserWalletId: String? { userWalletRepository.selectedModel?.userWalletId.stringValue }

//    private func bind() {
//        allSessions
//            .map { [weak self] newSessions in
//                newSessions.filter { $0.userWalletId == self?.currentUserWalletId }
//            }
//            .assign(to: \._sessions, on: self, ownership: .weak)
//    }

    func restoreAllSessions() {
        Task { [weak self] in
            guard let self else { return }

            var savedSessions: [WalletConnectSavedSession] = await (try? storage.value(for: .allWalletConnectSessions)) ?? []

            var shouldOverwriteAllSavedSessions = false
            for userWallet in await userWalletRepository.models {
                if let oldSavedSessions: [WalletConnectSavedSession] = try? await storage.value(for: .walletConnectSessions(userWalletId: userWallet.userWalletId.stringValue)) {
                    savedSessions.append(contentsOf: oldSavedSessions)
                    try? await storage.store(value: [WalletConnectSavedSession](), for: .walletConnectSessions(userWalletId: userWallet.userWalletId.stringValue))
                    shouldOverwriteAllSavedSessions = true
                }
            }

            allSessions.value = savedSessions

            if shouldOverwriteAllSavedSessions {
                await saveSessionsToFile()
            }
        }
    }

    private func readSessionsFromFile(with key: String) -> [WalletConnectSavedSession] {
        let savedSessions: [WalletConnectSavedSession] = (try? storage.value(for: .walletConnectSessions(userWalletId: key))) ?? []
        return savedSessions
    }

    private func saveSessionsToFile() {
        do {
            try storage.store(value: allSessions.value, for: .allWalletConnectSessions)
//            try storage.store(value: _sessions, for: .walletConnectSessions(userWalletId: currentUserWalletId))
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

    func loadSessions(for userWalletId: String) -> [WalletConnectSavedSession] {
//        currentUserWalletId = userWalletId
//        let savedSessions = readSessionsFromFile(with: userWalletId)
//        _sessions = savedSessions
//        return savedSessions
        return []
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
        print(allSessions.value)
        print("Found session: \(session)")
        return session
    }

    func removeSession(with id: Int) {
        guard let session = session(with: id) else { return }

        remove(session)
    }

    func remove(_ session: WalletConnectSavedSession) {
        allSessions.value.remove(session)
        saveSessionsToFile()
    }

    func removeSessions(for userWalletId: String) -> [WalletConnectSavedSession] {
        var sessions = allSessions.value
        var removedSessions = [WalletConnectSavedSession]()
        for i in stride(from: sessions.endIndex - 1, to: 0, by: -1) {
            let session = sessions[i]
            if session.userWalletId == userWalletId {
                sessions.remove(at: i)
                removedSessions.append(session)
            }
        }

        if removedSessions.isEmpty {
            return []
        }

        allSessions.value = sessions
        return removedSessions
    }
}
