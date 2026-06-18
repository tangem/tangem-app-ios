//
//  CommonWalletAssetsDiscoveryOrchestrator.swift
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

final class CommonWalletAssetsDiscoveryOrchestrator {
    private let syncStateActor: WalletAssetsDiscoveryStateActor
    private let progressService: WalletAssetsDiscoveryProgressService
    private let persister: WalletAssetsDiscoveryPersister
    private let relayerFactory: (Blockchain) -> (any WalletAssetsDiscoveryRelayer)?
    private let userWalletRepository: UserWalletRepository
    private let apiListProvider: APIListProvider
    private let analyticsProvider: WalletAssetsDiscoveryAnalyticsProvider

    private let walletDidCreateSubject = PassthroughSubject<UserWalletId, Never>()
    private var cancellables = Set<AnyCancellable>()

    init(
        syncStateActor: WalletAssetsDiscoveryStateActor,
        progressService: WalletAssetsDiscoveryProgressService,
        persister: WalletAssetsDiscoveryPersister,
        relayerFactory: @escaping (Blockchain) -> (any WalletAssetsDiscoveryRelayer)?,
        userWalletRepository: UserWalletRepository,
        apiListProvider: APIListProvider,
        analyticsProvider: WalletAssetsDiscoveryAnalyticsProvider
    ) {
        self.syncStateActor = syncStateActor
        self.progressService = progressService
        self.persister = persister
        self.relayerFactory = relayerFactory
        self.userWalletRepository = userWalletRepository
        self.apiListProvider = apiListProvider
        self.analyticsProvider = analyticsProvider

        bindDeletedWalletsPipeline()
        bindStartSyncPipeline()
    }
}

// MARK: - WalletLifecycleObserver

extension CommonWalletAssetsDiscoveryOrchestrator: WalletLifecycleObserver {
    func walletDidCreate(with userWalletId: UserWalletId) {
        walletDidCreateSubject.send(userWalletId)
    }
}

// MARK: - Private Implementation

private extension CommonWalletAssetsDiscoveryOrchestrator {
    func bindDeletedWalletsPipeline() {
        userWalletRepository.eventProvider
            .compactMap { event -> [UserWalletId]? in
                guard case .deleted(let userWalletIds, _) = event else {
                    return nil
                }

                return userWalletIds
            }
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { service, userWalletIds in
                service.handleDeletedWallets(userWalletIds)
            }
            .store(in: &cancellables)
    }

    func bindStartSyncPipeline() {
        let repositoryStartSyncPublisher = userWalletRepository.eventProvider
            .compactMap { event -> UserWalletId? in
                switch event {
                case .inserted(let userWalletId):
                    return userWalletId
                default:
                    return nil
                }
            }

        Publishers.Merge(
            walletDidCreateSubject.eraseToAnyPublisher(),
            repositoryStartSyncPublisher.eraseToAnyPublisher()
        )
        .receiveOnMain()
        .withWeakCaptureOf(self)
        .compactMap { service, userWalletId -> UserWalletModel? in
            service.userWalletRepository.models.first(where: { $0.userWalletId == userWalletId })
        }
        .withWeakCaptureOf(self)
        .flatMapLatest { service, userWalletModel -> AnyPublisher<UserWalletModel, Never> in
            let cryptoAccountModelsReady = userWalletModel.accountModelsManager.cryptoAccountModelsPublisher
                .filter { cryptoAccountModels in
                    cryptoAccountModels.contains(where: { $0.isMainAccount })
                }
                .prefix(1)

            let apiListReady = service.apiListProvider.apiListPublisher
                .filter { !$0.isEmpty }
                .prefix(1)

            return Publishers.CombineLatest(cryptoAccountModelsReady, apiListReady)
                .mapToValue(userWalletModel)
                .eraseToAnyPublisher()
        }
        .receiveOnMain()
        .withWeakCaptureOf(self)
        .sink { service, userWalletModel in
            service.handleStartSync(userWalletModel: userWalletModel)
        }
        .store(in: &cancellables)
    }

    func handleStartSync(userWalletModel: UserWalletModel) {
        Task { [weak self] in
            await self?.attemptStartSync(userWalletModel: userWalletModel)
        }
    }

    func handleDeletedWallets(_ userWalletIds: [UserWalletId]) {
        Task { [weak self] in
            for userWalletId in userWalletIds {
                await self?.syncStateActor.cancelAndUnregister(userWalletId: userWalletId)
                await self?.progressService.remove(userWalletId: userWalletId)
            }
        }
    }

    func attemptStartSync(userWalletModel: UserWalletModel) async {
        let userWalletId = userWalletModel.userWalletId

        guard
            userWalletModel.config.hasFeature(.walletAssetsDiscovery),
            userWalletModel.hasImportedWallets
        else {
            AssetsDiscoveryLogger.debug("Skip \(userWalletId.stringValue): token discovery is not supported")
            return
        }

        do {
            try await syncStateActor.startIfPossible(
                userWalletId: userWalletId,
                operation: { [weak self] in
                    guard let self else { return }
                    let keyInfos = userWalletModel.keysRepository.keys
                    await performSync(userWalletModel: userWalletModel, keyInfos: keyInfos)
                }
            )
        } catch {
            AssetsDiscoveryLogger.debug("Skip \(userWalletId.stringValue): \(error)")
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

            // Sliding window + progressive flush.
            //
            // Tokens from completed tasks are accumulated in `state.pendingToWrite`
            // and flushed to `accountModelsManager` whenever the completion
            // progress crosses the next `syncFlushProgressStep` threshold
            // (e.g. 20%, 40%, ...). The next sync task is enqueued *before*
            // we start flushing so persistence overlaps with the next
            // network round-trip — the user sees tokens appearing on the
            // main screen incrementally instead of in one delayed batch.
            var state = SyncFlushState()

            try await Self.runWithSlidingWindow(
                items: relayerPairs,
                limit: Constants.maxConcurrentSyncTasks,
                operation: { [weak self] pair in
                    guard let self else {
                        throw SyncOrchestrationError.orchestratorDeallocatedDuringSync
                    }
                    let (blockchain, relayer) = pair
                    let blockchainNetwork = BlockchainNetwork(
                        blockchain,
                        derivationPath: blockchain.derivationPath(for: derivationStyle)
                    )
                    return await syncTokens(
                        blockchainNetwork: blockchainNetwork,
                        relayer: relayer,
                        addressResolver: addressResolver,
                        keyInfos: keyInfos
                    )
                },
                onResult: { [weak self] tokens in
                    guard let self else {
                        throw SyncOrchestrationError.orchestratorDeallocatedDuringSync
                    }
                    try await processSyncResult(
                        tokens: tokens,
                        state: &state,
                        userWalletId: userWalletId,
                        accountModelsManager: accountModelsManager,
                        totalNetworks: totalNetworks
                    )
                }
            )

            // Tail flush — write whatever was buffered after the last
            // threshold so no discovered tokens are lost regardless of
            // how the final batch lined up with `totalNetworks`.
            if state.pendingToWrite.isNotEmpty {
                try Task.checkCancellation()

                await persister.syncDiscoveredTokensWithAccounts(
                    discoveredTokens: state.pendingToWrite,
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

    /// Per-network sync result handler used as the `onResult` callback of
    /// `runWithSlidingWindow`.
    ///
    /// Accumulates discovered tokens, reports progress, and performs an
    /// intermediate flush whenever the completion percentage crosses the
    /// next `Constants.syncFlushProgressStep` threshold. The tail flush
    /// (for the buffer left after the final threshold) is the caller's
    /// responsibility.
    func processSyncResult(
        tokens: [TokenItem],
        state: inout SyncFlushState,
        userWalletId: UserWalletId,
        accountModelsManager: AccountModelsManager,
        totalNetworks: Int
    ) async throws {
        state.pendingToWrite.append(contentsOf: tokens)
        state.completedCount += 1

        let percent = Int((Double(state.completedCount) / Double(totalNetworks)) * 100)
        await progressService.reportProgress(userWalletId: userWalletId, percent: min(percent, 99))

        guard
            percent - state.lastFlushedPercent >= Constants.syncFlushProgressStep,
            state.pendingToWrite.isNotEmpty
        else {
            return
        }

        try Task.checkCancellation()

        await persister.syncDiscoveredTokensWithAccounts(
            discoveredTokens: state.pendingToWrite,
            accountModelsManager: accountModelsManager
        )
        state.pendingToWrite.removeAll()
        state.lastFlushedPercent = percent
    }

    func syncTokens(
        blockchainNetwork: BlockchainNetwork,
        relayer: any WalletAssetsDiscoveryRelayer,
        addressResolver: WalletAddressResolver,
        keyInfos: [KeyInfo]
    ) async -> [TokenItem] {
        let networkAddressPair: NetworkAddressPair
        do {
            networkAddressPair = try addressResolver.resolveAddress(for: blockchainNetwork, keyInfos: keyInfos)
        } catch {
            AssetsDiscoveryLogger.debug("Skip \(blockchainNetwork.blockchain.displayName): \(error)")
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
            AssetsDiscoveryLogger.debug("Skip \(blockchainNetwork.blockchain.displayName): \(error)")
            return []
        }
    }

    func resolveRelayerPairs(
        supportedBlockchains: Set<Blockchain>
    ) -> [(Blockchain, any WalletAssetsDiscoveryRelayer)] {
        supportedBlockchains
            .compactMap { blockchain -> (Blockchain, any WalletAssetsDiscoveryRelayer)? in
                guard let relayer = relayerFactory(blockchain) else {
                    return nil
                }

                return (blockchain, relayer)
            }
    }
}

private extension CommonWalletAssetsDiscoveryOrchestrator {
    /// Thrown when sliding-window closures run after `self` has been released (should not happen during a normal sync).
    enum SyncOrchestrationError: Swift.Error {
        case orchestratorDeallocatedDuringSync
    }

    enum Constants {
        static let syncFlushProgressStep = 20
        /// Number of simultaneously running per-network sync tasks.
        static let maxConcurrentSyncTasks = 4
    }

    /// Mutable state carried across `processSyncResult` invocations during a
    /// single `performSync` run.
    struct SyncFlushState {
        /// Tokens discovered since the last flush, awaiting persistence.
        var pendingToWrite: [TokenItem] = []
        /// Number of per-network sync tasks that have completed so far.
        var completedCount: Int = 0
        /// Completion percentage at which the last flush was performed.
        var lastFlushedPercent: Int = 0
    }
}

// MARK: - InjectedValues

private struct WalletLifecycleObserverKey: InjectionKey {
    static var currentValue: WalletLifecycleObserver = WalletAssetsDiscoveryOrchestratorFactory().makeOrchestrator()
}

extension InjectedValues {
    var walletLifecycleObserver: WalletLifecycleObserver {
        get { Self[WalletLifecycleObserverKey.self] }
        set { Self[WalletLifecycleObserverKey.self] = newValue }
    }
}

// MARK: - Concurrency Helpers

private extension CommonWalletAssetsDiscoveryOrchestrator {
    /// Bounded-concurrency fan-out with a sliding window for throwing tasks.
    ///
    /// Runs at most `limit` tasks concurrently: the window is pre-filled with the
    /// first `limit` items, and after each task completes the next item is enqueued
    /// *before* `onResult` is invoked. This lets the caller (e.g. a persister flush)
    /// run in parallel with the next network round-trip, preserving the exact
    /// behavior of the hand-written sliding-window implementation in `performSync`.
    ///
    /// - Note: `onResult` always runs sequentially on the parent task within the
    ///   `withThrowingTaskGroup` body, so it can safely mutate local `var`
    ///   bindings captured from the calling function.
    /// - Note: If `operation` or `onResult` throws, the underlying
    ///   `ThrowingTaskGroup` cancels the remaining tasks and rethrows the error.
    static func runWithSlidingWindow<Item, Result>(
        items: [Item],
        limit: Int,
        operation: @escaping @Sendable (Item) async throws -> Result,
        onResult: (Result) async throws -> Void
    ) async throws {
        guard !items.isEmpty, limit > 0 else { return }

        try await withThrowingTaskGroup(of: Result.self) { group in
            var iterator = items.makeIterator()

            func enqueueNext() {
                guard let item = iterator.next() else { return }
                _ = group.addTaskUnlessCancelled {
                    try Task.checkCancellation()
                    return try await operation(item)
                }
            }

            for _ in 0 ..< limit {
                enqueueNext()
            }

            while let result = try await group.next() {
                try Task.checkCancellation()
                enqueueNext()
                try await onResult(result)
            }
        }
    }
}
