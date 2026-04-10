//
//  PersistentStorageWalletConnectConnectedDAppRepository.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

actor PersistentStorageWalletConnectConnectedDAppRepository: WalletConnectConnectedDAppRepository {
    private let persistentStorage: any PersistentStorageProtocol
    private var inMemoryCache: [WalletConnectConnectedDApp]
    private var dAppsBySessionTopic: [String: [WalletConnectConnectedDApp]]
    private var isWarmedUp = false

    private var continuations: [UUID: AsyncStream<[WalletConnectConnectedDApp]>.Continuation] = [:]

    var prefetchedDApps: [WalletConnectConnectedDApp]? {
        guard isWarmedUp else {
            return nil
        }
        return inMemoryCache
    }

    init(persistentStorage: some PersistentStorageProtocol) {
        self.persistentStorage = persistentStorage
        inMemoryCache = []
        dAppsBySessionTopic = [:]
    }

    func makeDAppsStream() -> AsyncStream<[WalletConnectConnectedDApp]> {
        AsyncStream { continuation in
            let id = UUID()
            continuations[id] = continuation

            continuation.onTermination = { [weak self] _ in
                guard let self else { return }
                Task { await self.removeContinuation(with: id) }
            }

            // Emit current snapshot immediately so new subscribers start with actual state.
            // If fetch fails, we still yield the current in-memory cache (possibly empty).
            try? fetchIfNeeded()
            continuation.yield(inMemoryCache)
        }
    }

    func save(dApp: WalletConnectConnectedDApp) throws(WalletConnectDAppPersistenceError) {
        try fetchIfNeeded()

        var updatedCache = inMemoryCache

        if let existingIndex = updatedCache.firstIndex(where: { $0.matchesIdentity(of: dApp) }) {
            updatedCache[existingIndex] = dApp
        } else {
            updatedCache.append(dApp)
        }

        try commitCache(updatedCache)
    }

    func getDApp(with sessionTopic: String) throws(WalletConnectDAppPersistenceError) -> WalletConnectConnectedDApp {
        try fetchIfNeeded()

        guard let dApp = dAppsBySessionTopic[sessionTopic]?.first else {
            throw WalletConnectDAppPersistenceError.notFound
        }

        return dApp
    }

    func getDApps(with sessionTopic: String) throws(WalletConnectDAppPersistenceError) -> [WalletConnectConnectedDApp] {
        try fetchIfNeeded()

        return dAppsBySessionTopic[sessionTopic] ?? []
    }

    func getDApps(forUserWalletId userWalletId: String) throws(WalletConnectDAppPersistenceError) -> [WalletConnectConnectedDApp] {
        try fetchIfNeeded()

        return inMemoryCache.compactMap { dApp in
            switch dApp {
            case .v1(let model):
                if model.userWalletID == userWalletId {
                    return dApp
                }
            case .v2(let model):
                if model.wrapped.userWalletID == userWalletId {
                    return dApp
                }
            }

            return nil
        }
    }

    func getAllDApps() throws(WalletConnectDAppPersistenceError) -> [WalletConnectConnectedDApp] {
        if let prefetchedDApps {
            return prefetchedDApps
        }

        try fetchIfNeeded()
        broadcast(inMemoryCache)

        return inMemoryCache
    }

    func replacingAllExistingDApps(with dApps: [WalletConnectConnectedDApp]) throws(WalletConnectDAppPersistenceError) {
        try fetchIfNeeded()

        try commitCache(dApps)
    }

    func replaceExistingDApp(with updatedDApp: WalletConnectConnectedDApp) throws(WalletConnectDAppPersistenceError) {
        try fetchIfNeeded()

        guard let dAppToReplaceIndex = inMemoryCache.firstIndex(where: { $0.matchesIdentity(of: updatedDApp) }) else {
            throw WalletConnectDAppPersistenceError.notFound
        }

        var updatedCache = inMemoryCache
        updatedCache[dAppToReplaceIndex] = updatedDApp

        try commitCache(updatedCache)
    }

    func deleteDApp(with sessionTopic: String) throws(WalletConnectDAppPersistenceError) {
        try fetchIfNeeded()

        let updatedCache = inMemoryCache.filter { $0.session.topic != sessionTopic }
        try commitCache(updatedCache)
    }

    func delete(dApps: [WalletConnectConnectedDApp]) throws(WalletConnectDAppPersistenceError) {
        try fetchIfNeeded()

        let dAppsToRemove = Set(dApps)
        let filteredDApps = inMemoryCache.filter { !dAppsToRemove.contains($0) }

        try commitCache(filteredDApps)
    }

    func deleteDApps(forUserWalletId userWalletId: String) throws(WalletConnectDAppPersistenceError) -> [WalletConnectConnectedDApp] {
        try fetchIfNeeded()

        var retained: [WalletConnectConnectedDApp] = []
        var removed: [WalletConnectConnectedDApp] = []

        for dApp in inMemoryCache {
            switch dApp {
            case .v1(let model) where model.userWalletID == userWalletId:
                removed.append(dApp)
            case .v2(let model) where model.wrapped.userWalletID == userWalletId:
                removed.append(dApp)
            default:
                retained.append(dApp)
            }
        }

        try commitCache(retained)

        return removed
    }

    // MARK: - Streaming helpers

    private func broadcast(_ dApps: [WalletConnectConnectedDApp]) {
        continuations.values.forEach { $0.yield(dApps) }
    }

    private func removeContinuation(with id: UUID) {
        continuations[id] = nil
    }

    private func fetchIfNeeded() throws(WalletConnectDAppPersistenceError) {
        guard !isWarmedUp else { return }

        do {
            let dAppDTOs: [WalletConnectConnectedDAppPersistentDTO]? = try persistentStorage.value(for: .walletConnectSessions)
            let dApps = dAppDTOs?.map(WalletConnectConnectedDAppMapper.mapToDomain) ?? []
            isWarmedUp = true
            inMemoryCache = dApps
            rebuildTopicIndex()
        } catch {
            throw WalletConnectDAppPersistenceError.retrievingFailed
        }
    }

    private func commitCache(_ allDApps: [WalletConnectConnectedDApp]) throws(WalletConnectDAppPersistenceError) {
        inMemoryCache = allDApps
        rebuildTopicIndex()
        try persist(allDApps)
        broadcast(allDApps)
    }

    private func rebuildTopicIndex() {
        dAppsBySessionTopic = Dictionary(grouping: inMemoryCache, by: { $0.session.topic })
    }

    private func persist(_ allDApps: [WalletConnectConnectedDApp]) throws(WalletConnectDAppPersistenceError) {
        let dtos = allDApps.map(WalletConnectConnectedDAppMapper.mapFromDomain)

        do {
            try persistentStorage.store(value: dtos, for: .walletConnectSessions)
        } catch {
            throw WalletConnectDAppPersistenceError.savingFailed
        }
    }
}

private extension WalletConnectConnectedDApp {
    func matchesIdentity(of other: WalletConnectConnectedDApp) -> Bool {
        session.topic == other.session.topic && accountId == other.accountId
    }
}
