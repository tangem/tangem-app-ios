//
//  CommonWalletTokenAutoSyncOrchestrator.swift
//  Tangem
//
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt
import TangemFoundation
import BlockchainSdk
import TangemSdk

final class CommonWalletTokenAutoSyncOrchestrator {
    private let syncStateActor: WalletTokenAutoSyncStateActor
    private let progressService: WalletTokenAutoSyncProgressService
    private let relayerFactory: (Blockchain) -> (any WalletTokenAutoSyncRelayer)?

    init(
        syncStateActor: WalletTokenAutoSyncStateActor,
        progressService: WalletTokenAutoSyncProgressService,
        relayerFactory: @escaping (Blockchain) -> (any WalletTokenAutoSyncRelayer)?
    ) {
        self.syncStateActor = syncStateActor
        self.progressService = progressService
        self.relayerFactory = relayerFactory
    }
}

// MARK: - WalletTokenAutoSyncInteractor

extension CommonWalletTokenAutoSyncOrchestrator: WalletTokenAutoSyncInteractor {
    func startIfPossible(userWalletModel: UserWalletModel, keyInfos: [KeyInfo]) async throws {
        let userWalletId = userWalletModel.userWalletId
        let stateActor = syncStateActor
        try await stateActor.tryRegister(userWalletId: userWalletId)

        Task(priority: .utility) { [weak self] in
            do {
                try await self?.performSync(userWalletModel: userWalletModel, keyInfos: keyInfos)
            } catch {
                AppLogger.tag("CommonWalletTokenAutoSyncOrchestrator").error("Sync failed", error: error)
            }

            await stateActor.unregister(userWalletId: userWalletId)
        }
    }
}

// MARK: - Private

private extension CommonWalletTokenAutoSyncOrchestrator {
    func performSync(userWalletModel: UserWalletModel, keyInfos: [KeyInfo]) async throws {
        let userWalletId = userWalletModel.userWalletId

        await progressService.add(userWalletId: userWalletId)

        let relayerPairs = resolveRelayerPairs()
        let totalNetworks = relayerPairs.count
        var allTokens: [TokenItem] = []

        for (index, (blockchain, relayer)) in relayerPairs.enumerated() {
            if Task.isCancelled { break }

            do {
                let stream = try await relayer.resolveTokenStream(
                    blockchain: blockchain,
                    keyInfos: keyInfos
                )

                for try await token in stream {
                    if Task.isCancelled { break }
                    allTokens.append(token)
                }
            } catch {
                AppLogger.tag("WalletTokenAutoSync").debug("Skip \(blockchain.displayName): \(error)")
            }

            let percent = Int((Double(index + 1) / Double(totalNetworks)) * 100)
            await progressService.reportProgress(userWalletId: userWalletId, percent: min(percent, 99))
        }

        if !allTokens.isEmpty {
            await syncDiscoveredTokensWithAccounts(
                discoveredTokens: allTokens,
                accountModelsManager: userWalletModel.accountModelsManager
            )
        }

        await progressService.reportProgress(userWalletId: userWalletId, percent: 100)
    }

    func resolveRelayerPairs() -> [(Blockchain, any WalletTokenAutoSyncRelayer)] {
        SupportedBlockchains.all
            .compactMap { blockchain -> (Blockchain, any WalletTokenAutoSyncRelayer)? in
                guard let relayer = relayerFactory(blockchain) else {
                    return nil
                }

                return (blockchain, relayer)
            }
    }

    func syncDiscoveredTokensWithAccounts(
        discoveredTokens: [TokenItem],
        accountModelsManager: AccountModelsManager,
        attempt: Int = 0
    ) async {
        do {
            try await waitForTokenListReady(accountModelsManager: accountModelsManager)

            addNewTokensToMainAccount(
                discoveredTokens: discoveredTokens,
                accountModelsManager: accountModelsManager
            )
        } catch {
            guard attempt < Constants.maxSyncRetries, !Task.isCancelled else {
                AppLogger.tag("WalletTokenAutoSync").error("Failed to sync discovered tokens after \(attempt) attempts", error: error)
                return
            }

            AppLogger.tag("WalletTokenAutoSync").debug("Token list not ready, retry \(attempt + 1)/\(Constants.maxSyncRetries)")

            await syncDiscoveredTokensWithAccounts(
                discoveredTokens: discoveredTokens,
                accountModelsManager: accountModelsManager,
                attempt: attempt + 1
            )
        }
    }

    func waitForTokenListReady(accountModelsManager: AccountModelsManager) async throws {
        try await accountModelsManager
            .cryptoAccountModelsPublisher
            .setFailureType(to: WalletTokenAutoSyncError.self)
            .flatMapLatest { cryptoAccountModels -> AnyPublisher<Void, WalletTokenAutoSyncError> in
                guard cryptoAccountModels.isNotEmpty else {
                    return Fail(error: .userTokenListNotReady).eraseToAnyPublisher()
                }

                return cryptoAccountModels
                    .map { $0.userTokensManager.userTokensPublisher }
                    .combineLatest()
                    .map { _ in () }
                    .setFailureType(to: WalletTokenAutoSyncError.self)
                    .eraseToAnyPublisher()
            }
            .timeout(
                .seconds(Constants.syncTimeoutSeconds),
                scheduler: DispatchQueue.main,
                customError: { .userTokenListNotReady }
            )
            .async()
    }

    func addNewTokensToMainAccount(
        discoveredTokens: [TokenItem],
        accountModelsManager: AccountModelsManager
    ) {
        guard let mainAccount = accountModelsManager.cryptoAccountModels.first(where: { $0.isMainAccount }) else {
            AppLogger.tag("WalletTokenAutoSync").debug("No main crypto account found, skipping token persistence")
            return
        }

        let newTokens = discoveredTokens.filter { token in
            !mainAccount.userTokensManager.contains(token, derivationInsensitive: false)
        }

        guard newTokens.isNotEmpty else {
            AppLogger.tag("WalletTokenAutoSync").debug("No new tokens to add, all already present")
            return
        }

        do {
            try mainAccount.userTokensManager.update(itemsToRemove: [], itemsToAdd: newTokens)
            AppLogger.tag("WalletTokenAutoSync").debug("Added \(newTokens.count) new tokens to main account")
        } catch {
            AppLogger.tag("WalletTokenAutoSync").error("Failed to add tokens to main account", error: error)
        }
    }
}

private extension CommonWalletTokenAutoSyncOrchestrator {
    enum Constants {
        static let maxSyncRetries = 5
        static let syncTimeoutSeconds = 3
    }
}

// MARK: - InjectedValues

extension InjectedValues {
    var walletTokenAutoSyncInteractor: WalletTokenAutoSyncInteractor {
        shared
    }

    private var shared: CommonWalletTokenAutoSyncOrchestrator {
        get { Self[Key.self] }
        set { Self[Key.self] = newValue }
    }

    private struct Key: InjectionKey {
        static var currentValue: CommonWalletTokenAutoSyncOrchestrator = WalletTokenAutoSyncOrchestratorFactory().makeOrchestrator()
    }
}
