//
//  WalletConnectConnectedDAppRepository.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

protocol WalletConnectConnectedDAppRepository {
    /// Prefetched dApps if any.
    /// - Note: Does not await except for the actors hopping.
    var prefetchedDApps: [WalletConnectConnectedDApp]? { get async }

    func makeDAppsStream() async -> AsyncStream<[WalletConnectConnectedDApp]>

    func save(dApp: WalletConnectConnectedDApp) async throws(WalletConnectDAppPersistenceError)

    func getDApp(with sessionTopic: String) async throws(WalletConnectDAppPersistenceError) -> WalletConnectConnectedDApp
    func getDApps(forUserWalletId userWalletId: String) async throws(WalletConnectDAppPersistenceError) -> [WalletConnectConnectedDApp]
    func getAllDApps() async throws(WalletConnectDAppPersistenceError) -> [WalletConnectConnectedDApp]

    func replacingAllExistingDApps(with dApps: [WalletConnectConnectedDApp]) async throws(WalletConnectDAppPersistenceError)
    func replaceExistingDApp(with updatedDApp: WalletConnectConnectedDApp) async throws(WalletConnectDAppPersistenceError)

    func deleteDApp(with sessionTopic: String) async throws(WalletConnectDAppPersistenceError)
    func delete(dApps: [WalletConnectConnectedDApp]) async throws(WalletConnectDAppPersistenceError)
    func deleteDApps(forUserWalletId userWalletId: String) async throws(WalletConnectDAppPersistenceError) -> [WalletConnectConnectedDApp]
}
