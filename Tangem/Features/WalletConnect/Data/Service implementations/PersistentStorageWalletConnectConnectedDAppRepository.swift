//
//  PersistentStorageWalletConnectConnectedDAppRepository.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

final class PersistentStorageWalletConnectConnectedDAppRepository: WalletConnectConnectedDAppRepository {
    private let persistentStorage: any PersistentStorageProtocol
    private let inMemoryCache: InMemoryCache

    private var continuation: AsyncStream<[WalletConnectConnectedDApp]>.Continuation?

    init(persistentStorage: some PersistentStorageProtocol) {
        self.persistentStorage = persistentStorage
        inMemoryCache = InMemoryCache()
    }

    func makeDAppsStream() async -> AsyncStream<[WalletConnectConnectedDApp]> {
        let allDApps = await inMemoryCache.retrieveAllDApps()

        return AsyncStream { continuation in
            self.continuation = continuation
            continuation.yield(allDApps)
        }
    }

    func replacingExistingDApps(with dApps: [WalletConnectConnectedDApp]) async throws(WalletConnectDAppPersistenceError) {
        await inMemoryCache.replace(dApps: dApps)
        try await persist(dApps)
        continuation?.yield(dApps)
    }

    func save(dApp: WalletConnectConnectedDApp) async throws(WalletConnectDAppPersistenceError) {
        let allDApps = await inMemoryCache.storeDAppAndRetrieveAll(dApp)
        try await persist(allDApps)
        continuation?.yield(allDApps)
    }

    func getDApp(with sessionTopic: String) async throws(WalletConnectDAppPersistenceError) -> WalletConnectConnectedDApp {
        guard let dApp = await inMemoryCache.retrieveDApp(for: sessionTopic) else {
            throw WalletConnectDAppPersistenceError.notFound
        }

        return dApp
    }

    func getAllDApps() async throws(WalletConnectDAppPersistenceError) -> [WalletConnectConnectedDApp] {
        let dAppDTOs: [WalletConnectConnectedDAppPersistentDTO]?

        do {
            dAppDTOs = try persistentStorage.value(for: .walletConnectSessions)
        } catch {
            throw WalletConnectDAppPersistenceError.retrievingFailed
        }

        let dApps = dAppDTOs?.map(WalletConnectConnectedDAppMapper.mapToDomain) ?? []

        await inMemoryCache.storeDApps(dApps)
        continuation?.yield(dApps)

        return dApps
    }

    func deleteDApp(with sessionTopic: String) async throws(WalletConnectDAppPersistenceError) {
        let (deletedDApp, allDApps) = await inMemoryCache.removeDAppAndRetrieveAll(for: sessionTopic)

        guard deletedDApp != nil else {
            throw WalletConnectDAppPersistenceError.notFound
        }

        try await persist(allDApps)
        continuation?.yield(allDApps)
    }

    func deleteDApps(forUserWalletID userWalletID: String) async throws(WalletConnectDAppPersistenceError) -> [WalletConnectConnectedDApp] {
        var filteredDApps = await inMemoryCache.retrieveAllDApps()
        var removedDApps = [WalletConnectConnectedDApp]()

        for i in stride(from: filteredDApps.count - 1, through: .zero, by: -1) {
            if filteredDApps[i].userWallet.id == userWalletID {
                removedDApps.append(filteredDApps.remove(at: i))
            }
        }

        await inMemoryCache.replace(dApps: filteredDApps)
        continuation?.yield(filteredDApps)

        return removedDApps
    }

    private func persist(_ allDApps: [WalletConnectConnectedDApp]) async throws(WalletConnectDAppPersistenceError) {
        let dtos = allDApps.map(WalletConnectConnectedDAppMapper.mapFromDomain)

        do {
            try persistentStorage.store(value: dtos, for: .walletConnectSessions)
        } catch {
            throw WalletConnectDAppPersistenceError.savingFailed
        }
    }
}

extension PersistentStorageWalletConnectConnectedDAppRepository {
    private actor InMemoryCache {
        private var sessionTopicToConnectedDApp = [String: WalletConnectConnectedDApp]()

        func storeDApps(_ dApps: [WalletConnectConnectedDApp]) {
            dApps.forEach(storeDApp)
        }

        func storeDAppAndRetrieveAll(_ dApp: WalletConnectConnectedDApp) -> [WalletConnectConnectedDApp] {
            storeDApp(dApp)
            return retrieveAllDApps()
        }

        func retrieveDApp(for sessionTopic: String) -> WalletConnectConnectedDApp? {
            sessionTopicToConnectedDApp[sessionTopic]
        }

        func retrieveAllDApps() -> [WalletConnectConnectedDApp] {
            Array(sessionTopicToConnectedDApp.values)
        }

        func removeDAppAndRetrieveAll(for sessionTopic: String) -> (WalletConnectConnectedDApp?, [WalletConnectConnectedDApp]) {
            (sessionTopicToConnectedDApp.removeValue(forKey: sessionTopic), retrieveAllDApps())
        }

        func replace(dApps: [WalletConnectConnectedDApp]) {
            sessionTopicToConnectedDApp.removeAll()
            dApps.forEach(storeDApp)
        }

        private func storeDApp(_ dApp: WalletConnectConnectedDApp) {
            sessionTopicToConnectedDApp[dApp.session.topic] = dApp
        }
    }
}
