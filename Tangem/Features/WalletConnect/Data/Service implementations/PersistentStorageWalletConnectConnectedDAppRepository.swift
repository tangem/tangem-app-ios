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

    private var continuation: AsyncStream<[WalletConnectConnectedDApp]>.Continuation?

    init(persistentStorage: some PersistentStorageProtocol) {
        self.persistentStorage = persistentStorage
        inMemoryCache = []
    }

    func makeDAppsStream() async -> AsyncStream<[WalletConnectConnectedDApp]> {
        AsyncStream { continuation in
            self.continuation = continuation
            continuation.yield(inMemoryCache)
        }
    }

    func replacingExistingDApps(with dApps: [WalletConnectConnectedDApp]) async throws(WalletConnectDAppPersistenceError) {
        inMemoryCache = dApps
        try await persist(inMemoryCache)
        continuation?.yield(inMemoryCache)
    }

    func save(dApp: WalletConnectConnectedDApp) async throws(WalletConnectDAppPersistenceError) {
        inMemoryCache.append(dApp)
        try await persist(inMemoryCache)
        continuation?.yield(inMemoryCache)
    }

    func getDApp(with sessionTopic: String) async throws(WalletConnectDAppPersistenceError) -> WalletConnectConnectedDApp {
        guard let dApp = inMemoryCache.first(where: { $0.session.topic == sessionTopic }) else {
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

        inMemoryCache = dApps
        continuation?.yield(inMemoryCache)

        return inMemoryCache
    }

    func deleteDApp(with sessionTopic: String) async throws(WalletConnectDAppPersistenceError) {
        inMemoryCache.removeAll(where: { $0.session.topic == sessionTopic })
        try await persist(inMemoryCache)
        continuation?.yield(inMemoryCache)
    }

    func deleteDApps(forUserWalletID userWalletID: String) async throws(WalletConnectDAppPersistenceError) -> [WalletConnectConnectedDApp] {
        var filteredDApps = inMemoryCache
        var removedDApps = [WalletConnectConnectedDApp]()

        for i in stride(from: filteredDApps.count - 1, through: .zero, by: -1) {
            if filteredDApps[i].userWalletID == userWalletID {
                removedDApps.append(filteredDApps.remove(at: i))
            }
        }

        inMemoryCache = filteredDApps
        continuation?.yield(inMemoryCache)

        return inMemoryCache
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
