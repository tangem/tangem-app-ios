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

        inMemoryCache.append(dApp)
        try persist(inMemoryCache)
        broadcast(inMemoryCache)
    }

    func getDApp(with sessionTopic: String) throws(WalletConnectDAppPersistenceError) -> WalletConnectConnectedDApp {
        try fetchIfNeeded()

        guard let dApp = inMemoryCache.first(where: { $0.session.topic == sessionTopic }) else {
            throw WalletConnectDAppPersistenceError.notFound
        }

        return dApp
    }

    func getDApps(forUserWalletId userWalletId: String) throws(WalletConnectDAppPersistenceError) -> [WalletConnectConnectedDApp] {
        try fetchIfNeeded()

        return inMemoryCache.compactMap { dApp in
            if case .v1(let model) = dApp, model.userWalletID == userWalletId {
                return dApp
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

        inMemoryCache = dApps
        try persist(inMemoryCache)
        broadcast(inMemoryCache)
    }

    func replaceExistingDApp(with updatedDApp: WalletConnectConnectedDApp) throws(WalletConnectDAppPersistenceError) {
        try fetchIfNeeded()

        guard let dAppToReplaceIndex = inMemoryCache.firstIndex(where: { $0.session.topic == updatedDApp.session.topic }) else {
            throw WalletConnectDAppPersistenceError.notFound
        }

        inMemoryCache[dAppToReplaceIndex] = updatedDApp
        try persist(inMemoryCache)
        broadcast(inMemoryCache)
    }

    func deleteDApp(with sessionTopic: String) throws(WalletConnectDAppPersistenceError) {
        try fetchIfNeeded()

        inMemoryCache.removeAll(where: { $0.session.topic == sessionTopic })
        try persist(inMemoryCache)
        broadcast(inMemoryCache)
    }

    func delete(dApps: [WalletConnectConnectedDApp]) throws(WalletConnectDAppPersistenceError) {
        try fetchIfNeeded()

        let dAppsToRemove = Set(dApps)
        let filteredDApps = inMemoryCache.filter { !dAppsToRemove.contains($0) }

        inMemoryCache = filteredDApps
        try persist(inMemoryCache)
        broadcast(inMemoryCache)
    }

    func deleteDApps(forAccountId accountId: String) throws(WalletConnectDAppPersistenceError) -> [WalletConnectConnectedDApp] {
        try fetchIfNeeded()

        var retained: [WalletConnectConnectedDApp] = []
        var removed: [WalletConnectConnectedDApp] = []

        for dApp in inMemoryCache {
            if case .v2(let model) = dApp, model.accountId == accountId {
                removed.append(dApp)
            } else {
                retained.append(dApp)
            }
        }

        inMemoryCache = retained
        try persist(inMemoryCache)
        broadcast(inMemoryCache)

        return removed
    }

    func deleteDApps(forUserWalletId userWalletId: String) throws(WalletConnectDAppPersistenceError) -> [WalletConnectConnectedDApp] {
        try fetchIfNeeded()

        var retained: [WalletConnectConnectedDApp] = []
        var removed: [WalletConnectConnectedDApp] = []

        for dApp in inMemoryCache {
            if case .v1(let model) = dApp, model.userWalletID == userWalletId {
                removed.append(dApp)
            } else {
                retained.append(dApp)
            }
        }

        inMemoryCache = retained
        try persist(inMemoryCache)
        broadcast(inMemoryCache)

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
        } catch {
            throw WalletConnectDAppPersistenceError.retrievingFailed
        }
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
