//
//  CommonWalletModelsManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt
import BlockchainSdk
import TangemSdk
import TangemFoundation
import TangemAnalytics
import TangemStaking

class CommonWalletModelsManager {
    private let walletManagersRepository: WalletManagersRepository
    private let walletModelsFactory: WalletModelsFactory
    private let derivationIndex: Int
    private let derivationStyle: DerivationStyle?

    /// We need to keep optional array to track state when wallet models array wasn't able to initialize
    /// This state can happen while app awaiting API list from server, because and Wallet managers can't be created without this info
    /// Nil state is not the same as an empty state, because user can remove all tokens from main and the array will be empty
    /// Also if we initialize CurrentValueSubject with empty array recipients will evaluate this state as an empty list
    private var _walletModels = CurrentValueSubject<[any WalletModel]?, Never>(nil)
    private var _initialized = false
    private var bag = Set<AnyCancellable>()

    /// An update is tracked only once per lifecycle of this manager.
    private var shouldTrackWalletModelsUpdate = true

    /// On a cold start, `updateAll(silent:)` is always called shortly after the initial wallet models are created,
    /// so the very first update triggered by `updateWalletModels(with:)` would be a duplicate and is skipped.
    private var shouldSkipUpdateOnInitialWalletModelsCreation = true

    init(
        walletManagersRepository: WalletManagersRepository,
        walletModelsFactory: WalletModelsFactory,
        derivationIndex: Int,
        derivationStyle: DerivationStyle?
    ) {
        self.walletManagersRepository = walletManagersRepository
        self.walletModelsFactory = walletModelsFactory
        self.derivationIndex = derivationIndex
        self.derivationStyle = derivationStyle
    }

    private func bind() {
        walletManagersRepository
            .walletManagersPublisher
            .sink { [weak self] managers in
                self?.updateWalletModels(with: managers)
            }
            .store(in: &bag)
    }

    private func updateWalletModels(with walletManagers: [BlockchainNetwork: WalletManager]) {
        let existingWalletModelIds = walletModels
            .map(\.id)
            .toSet()

        let newWalletModelIds = walletManagers
            .flatMap { network, walletManager in
                let mainId = WalletModelId(tokenItem: .blockchain(network))
                let tokenIds = walletManager.cardTokens.map { WalletModelId(tokenItem: .token($0, network)) }
                return [mainId] + tokenIds
            }
            .toSet()

        let walletModelIdsToDelete = existingWalletModelIds.subtracting(newWalletModelIds)
        let walletModelIdsToAdd = newWalletModelIds.subtracting(existingWalletModelIds)

        if walletModelIdsToAdd.isEmpty, walletModelIdsToDelete.isEmpty {
            // Case with first card scan without derivations
            if _walletModels.value == nil {
                _walletModels.send([]) // Emit initial list
            }

            shouldSkipUpdateOnInitialWalletModelsCreation = false // Allow subsequent updates when derivations are obtained

            return
        }

        var existingWalletModels = walletModels

        existingWalletModels.removeAll {
            walletModelIdsToDelete.contains($0.id)
        }

        let dataToAdd = Dictionary(grouping: walletModelIdsToAdd, by: { $0.tokenItem.blockchainNetwork })

        let walletModelsToAdd: [any WalletModel] = dataToAdd.flatMap {
            if let walletManager = walletManagers[$0.key] {
                let types = $0.value.map { $0.tokenItem.amountType }
                let targetPath = makeTargetDerivationPath(for: $0.key.blockchain)
                return walletModelsFactory.makeWalletModels(
                    for: types,
                    walletManager: walletManager,
                    blockchainNetwork: $0.key,
                    targetAccountDerivationPath: targetPath
                )
            }

            return []
        }

        if walletModelsToAdd.isNotEmpty {
            // Refresh only newly added wallet models. On a cold start, all wallet models are considered newly added.
            // Also on a cold start, `updateAll(silent:)` is always called shortly after these wallet models are created,
            // so the very first update triggered by this function would be a duplicate and therefore is skipped.
            if shouldSkipUpdateOnInitialWalletModelsCreation {
                shouldSkipUpdateOnInitialWalletModelsCreation = false
            } else {
                runTask(in: self) { manager in
                    await Self.updateAllInternal(
                        silent: false,
                        walletModels: walletModelsToAdd,
                        shouldTrackUpdate: &manager.shouldTrackWalletModelsUpdate
                    )
                }
            }

            existingWalletModels.append(contentsOf: walletModelsToAdd)
        }

        log(walletModels: existingWalletModels)

        _walletModels.send(existingWalletModels)
    }

    /// Must be stateless, therefore it's static.
    private static func updateAllInternal(
        silent: Bool,
        walletModels: [any WalletModel],
        shouldTrackUpdate: inout Bool
    ) async {
        var token: PerformanceMetricToken?

        if shouldTrackUpdate, walletModels.isNotEmpty {
            shouldTrackUpdate = false
            token = PerformanceTracker.startTracking(metric: .totalBalanceLoaded(tokensCount: walletModels.count))
        }

        // Even modern iOS devices, like iPhone 17 Pro/Pro Max, have at most 6 CPU cores
        // Therefore, n=5 is a reasonable limit for concurrent network requests (as for now)
        let maxConcurrentUpdates = 5
        let count = walletModels.count
        // [REDACTED_TODO_COMMENT]
        let options: WalletModelUpdateOptions = FeatureProvider.isAvailable(.transactionHistoryV2) ? .full : .balances
        // Single token shared across the batch of all wallet models, so all updates belong to the same cycle
        let updateToken = UUID()

        await withTaskGroup(of: Void.self) { group in
            for index in 0 ..< count {
                // Maintain a sliding window of concurrent updates with a maximum size of `maxConcurrentUpdates`
                if index >= maxConcurrentUpdates {
                    await group.next()
                }
                _ = group.addTaskUnlessCancelled {
                    // Coalesce this whole refresh cycle's P2P staking balances into one batched request.
                    await walletModels[index].update(
                        silent: silent,
                        options: options,
                        updateToken: updateToken,
                        stakingUpdateSource: .batch
                    )
                }
            }
            await group.waitForAll()
        }

        PerformanceTracker.endTracking(
            token: token,
            with: walletModels.contains(where: \.state.isBlockchainUnreachable) ? .failure : .success
        )
    }
}

// MARK: - Initializable protocol conformance

extension CommonWalletModelsManager: Initializable {
    func initialize() {
        if _initialized {
            return
        }

        bind()
        _initialized = true
    }
}

// MARK: - WalletModelsManager protocol conformance

extension CommonWalletModelsManager: WalletModelsManager {
    var isInitialized: Bool { _walletModels.value != nil }

    var walletModels: [any WalletModel] {
        _walletModels.value ?? []
    }

    var walletModelsPublisher: AnyPublisher<[any WalletModel], Never> {
        _walletModels
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }

    func updateAll(silent: Bool) async {
        await Self.updateAllInternal(silent: silent, walletModels: walletModels, shouldTrackUpdate: &shouldTrackWalletModelsUpdate)
    }
}

// MARK: - DisposableEntity protocol conformance

extension CommonWalletModelsManager: DisposableEntity {
    func dispose() {
        if _walletModels.value != nil {
            _walletModels.send([])
        }
    }
}

// MARK: - Convenience extensions

private extension CommonWalletModelsManager {
    func log(walletModels: [any WalletModel]) {
        AppLogger.info("✅ Actual List of WalletModels [\(walletModels.map(\.name))]")
    }

    /// - Note: Currently this method produces derivation path which is only used for determining if wallet models are
    /// custom or not (see `CommonWalletModelsFactory.isMainCoinCustom(blockchainDerivationPath:targetAccountDerivationPath:)`).
    func makeTargetDerivationPath(for blockchain: Blockchain) -> DerivationPath? {
        guard
            let derivationStyle,
            let defaultPath = blockchain.derivationPath(for: derivationStyle)
        else {
            return nil
        }

        do {
            let helper = AccountDerivationPathHelper(blockchain: blockchain)

            return try helper.makeDerivationPath(from: defaultPath, forAccountWithIndex: derivationIndex)
        } catch {
            // Ugly and explicit switch here due to https://github.com/swiftlang/swift/issues/74555 ([REDACTED_INFO])
            switch error {
            case .insufficientNodes:
                // Insufficient amount of nodes to create an accounts-aware derivation path means that
                // this blockchain (and therefore all its tokens) will be custom
                return defaultPath
            case .accountsUnavailableForBlockchain:
                return nil
            }
        }
    }
}
