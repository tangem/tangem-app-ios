//
//  CommonWalletTokenAutoSyncOrchestrator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
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
    private let persister: WalletTokenAutoSyncPersister
    private let relayerFactory: (Blockchain) -> (any WalletTokenAutoSyncRelayer)?
    private let userWalletRepository: UserWalletRepository
    private let analyticsProvider: WalletTokenAutoSyncAnalyticsProvider

    private var cancellables = Set<AnyCancellable>()

    init(
        syncStateActor: WalletTokenAutoSyncStateActor,
        progressService: WalletTokenAutoSyncProgressService,
        persister: WalletTokenAutoSyncPersister,
        relayerFactory: @escaping (Blockchain) -> (any WalletTokenAutoSyncRelayer)?,
        userWalletRepository: UserWalletRepository,
        analyticsProvider: WalletTokenAutoSyncAnalyticsProvider
    ) {
        self.syncStateActor = syncStateActor
        self.progressService = progressService
        self.persister = persister
        self.relayerFactory = relayerFactory
        self.userWalletRepository = userWalletRepository
        self.analyticsProvider = analyticsProvider
        bindUserWalletRepositoryEvents()
    }
}

// MARK: - WalletTokenAutoSyncInteractor

extension CommonWalletTokenAutoSyncOrchestrator: WalletTokenAutoSyncInteractor {
    func startIfPossible(userWalletModel: UserWalletModel, keyInfos: [KeyInfo]) async {
        let userWalletId = userWalletModel.userWalletId

        do {
            try await syncStateActor.executeIfPossible(userWalletId: userWalletId) { [weak self] in
                guard let self else {
                    return
                }

                await performSync(userWalletModel: userWalletModel, keyInfos: keyInfos)
            }
        } catch {
            AppLogger.tag("WalletTokenAutoSync").debug("Skip \(userWalletId.stringValue): \(error)")
        }
    }
}

// MARK: - Private

private extension CommonWalletTokenAutoSyncOrchestrator {
    func bindUserWalletRepositoryEvents() {
        userWalletRepository.eventProvider
            .receiveOnMain()
            .sink { [weak self] event in
                guard case .deleted(let userWalletIds, _) = event else {
                    return
                }

                self?.handleDeletedWallets(userWalletIds)
            }
            .store(in: &cancellables)
    }

    func handleDeletedWallets(_ userWalletIds: [UserWalletId]) {
        Task { [weak self] in
            for userWalletId in userWalletIds {
                await self?.syncStateActor.cancelAndUnregister(userWalletId: userWalletId)
                await self?.progressService.remove(userWalletId: userWalletId)
            }
        }
    }

    func performSync(userWalletModel: UserWalletModel, keyInfos: [KeyInfo]) async {
        // Derivation unsupported
        guard let derivationStyle = userWalletModel.config.derivationStyle else {
            return
        }

        let userWalletId = userWalletModel.userWalletId
        let addressResolver = WalletAddressResolver()

        await progressService.add(userWalletId: userWalletId)
        analyticsProvider.logInitialTokenSyncStarted(userWalletId: userWalletId)

        let accountModelsManager = userWalletModel.accountModelsManager
        do {
            let relayerPairs = resolveRelayerPairs(
                supportedBlockchains: userWalletModel.config.supportedBlockchains
            )

            let totalNetworks = relayerPairs.count

            let pendingTokens: [TokenItem] = try await withThrowingTaskGroup(of: [TokenItem].self) { group in
                for (blockchain, relayer) in relayerPairs {
                    let blockchainNetwork = BlockchainNetwork(blockchain, derivationPath: blockchain.derivationPath(for: derivationStyle))

                    group.addTask {
                        await self.syncTokens(
                            blockchainNetwork: blockchainNetwork,
                            relayer: relayer,
                            addressResolver: addressResolver,
                            keyInfos: keyInfos
                        )
                    }
                }

                return try await self.collectAndFlushTokens(
                    from: &group,
                    totalNetworks: totalNetworks,
                    userWalletId: userWalletId,
                    accountModelsManager: accountModelsManager
                )
            }

            try Task.checkCancellation()

            if pendingTokens.isNotEmpty {
                await persister.syncDiscoveredTokensWithAccounts(
                    discoveredTokens: pendingTokens,
                    accountModelsManager: accountModelsManager
                )
            }

            try Task.checkCancellation()

            await progressService.reportProgress(userWalletId: userWalletId, percent: 100)
            analyticsProvider.logInitialTokenSyncCompleted(userWalletId: userWalletId)
        } catch {
            await progressService.remove(userWalletId: userWalletId)
        }
    }

    func syncTokens(
        blockchainNetwork: BlockchainNetwork,
        relayer: any WalletTokenAutoSyncRelayer,
        addressResolver: WalletAddressResolver,
        keyInfos: [KeyInfo]
    ) async -> [TokenItem] {
        let networkAddressPair: NetworkAddressPair
        do {
            networkAddressPair = try addressResolver.resolveAddress(
                for: blockchainNetwork.blockchain,
                keyInfos: keyInfos
            )
        } catch {
            AppLogger.tag("WalletTokenAutoSync").debug("Skip \(blockchainNetwork.blockchain.displayName): \(error)")
            return []
        }

        do {
            let stream = try await relayer.resolveTokenStream(
                pair: networkAddressPair,
                keyInfos: keyInfos
            )

            var tokens: [TokenItem] = []

            for try await token in stream {
                if Task.isCancelled { break }
                tokens.append(token)
            }

            return tokens
        } catch {
            AppLogger.tag("WalletTokenAutoSync").debug("Skip \(blockchainNetwork.blockchain.displayName): \(error)")
            return []
        }
    }

    /// Collects token results from the task group and periodically flushes them to accounts.
    ///
    /// As each child task completes, its tokens are accumulated in a pending buffer.
    /// Every time the completion progress crosses the next ``Constants/syncFlushProgressStep`` threshold (e.g. 20%, 40%, …),
    /// the buffer is flushed via ``syncDiscoveredTokensWithAccounts`` and cleared.
    ///
    /// - Returns: Tokens that have not yet been flushed (accumulated after the last threshold crossing).
    ///   The caller is responsible for flushing the remaining tokens after the group finishes.
    func collectAndFlushTokens(
        from group: inout ThrowingTaskGroup<[TokenItem], any Error>,
        totalNetworks: Int,
        userWalletId: UserWalletId,
        accountModelsManager: AccountModelsManager
    ) async throws -> [TokenItem] {
        var pendingToWrite: [TokenItem] = []
        var completedCount = 0
        var lastFlushedPercent = 0

        for try await tokens in group {
            try Task.checkCancellation()

            pendingToWrite.append(contentsOf: tokens)
            completedCount += 1

            let percent = Int((Double(completedCount) / Double(totalNetworks)) * 100)
            await progressService.reportProgress(userWalletId: userWalletId, percent: min(percent, 99))

            if percent - lastFlushedPercent >= Constants.syncFlushProgressStep, pendingToWrite.isNotEmpty {
                try Task.checkCancellation()

                await persister.syncDiscoveredTokensWithAccounts(
                    discoveredTokens: pendingToWrite,
                    accountModelsManager: accountModelsManager
                )
                pendingToWrite.removeAll()
                lastFlushedPercent = percent
            }
        }

        return pendingToWrite
    }

    func resolveRelayerPairs(
        supportedBlockchains: Set<Blockchain>
    ) -> [(Blockchain, any WalletTokenAutoSyncRelayer)] {
        supportedBlockchains
            .compactMap { blockchain -> (Blockchain, any WalletTokenAutoSyncRelayer)? in
                guard let relayer = relayerFactory(blockchain) else {
                    return nil
                }

                return (blockchain, relayer)
            }
    }
}

private extension CommonWalletTokenAutoSyncOrchestrator {
    enum Constants {
        static let syncFlushProgressStep = 20
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
