//
//  PersistentStorageWalletConnectConnectedDAppRepository.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

actor PersistentStorageWalletConnectConnectedDAppRepository: WalletConnectConnectedDAppRepository {
    private let persistentStorage: any PersistentStorageProtocol
    private var inMemoryCache: [WalletConnectConnectedDApp]
    private var isWarmedUp = false

    private var continuation: AsyncStream<[WalletConnectConnectedDApp]>.Continuation?

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
            self.continuation = continuation
        }
    }

    func save(dApp: WalletConnectConnectedDApp) throws(WalletConnectDAppPersistenceError) {
        try fetchIfNeeded()

        inMemoryCache.append(dApp)
        try persist(inMemoryCache)
        continuation?.yield(inMemoryCache)
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
        continuation?.yield(inMemoryCache)

        return inMemoryCache
    }

    func replacingAllExistingDApps(with dApps: [WalletConnectConnectedDApp]) throws(WalletConnectDAppPersistenceError) {
        try fetchIfNeeded()

        inMemoryCache = dApps
        try persist(inMemoryCache)
        continuation?.yield(inMemoryCache)
    }

    func replaceExistingDApp(with updatedDApp: WalletConnectConnectedDApp) throws(WalletConnectDAppPersistenceError) {
        try fetchIfNeeded()

        guard let dAppToReplaceIndex = inMemoryCache.firstIndex(where: { $0.session.topic == updatedDApp.session.topic }) else {
            throw WalletConnectDAppPersistenceError.notFound
        }

        inMemoryCache[dAppToReplaceIndex] = updatedDApp
        try persist(inMemoryCache)
        continuation?.yield(inMemoryCache)
    }

    func deleteDApp(with sessionTopic: String) throws(WalletConnectDAppPersistenceError) {
        try fetchIfNeeded()

        inMemoryCache.removeAll(where: { $0.session.topic == sessionTopic })
        try persist(inMemoryCache)
        continuation?.yield(inMemoryCache)
    }

    func delete(dApps: [WalletConnectConnectedDApp]) throws(WalletConnectDAppPersistenceError) {
        try fetchIfNeeded()

        let dAppsToRemove = Set(dApps)
        let filteredDApps = inMemoryCache.filter { !dAppsToRemove.contains($0) }

        inMemoryCache = filteredDApps
        try persist(inMemoryCache)
        continuation?.yield(inMemoryCache)
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
        continuation?.yield(inMemoryCache)

        return removed
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
