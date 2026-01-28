//
//  CommonWalletModelsManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Combine
import CombineExt
import BlockchainSdk
import TangemSdk
import TangemFoundation

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
        AppLogger.info("🔄 Updating Wallet models")

        let existingWalletModelIds = Set(walletModels.map { $0.id })

        let newWalletModelIds = Set(walletManagers.flatMap { network, walletManager in
            let mainId = WalletModelId(tokenItem: .blockchain(network))
            let tokenIds = walletManager.cardTokens.map { WalletModelId(tokenItem: .token($0, network)) }
            return [mainId] + tokenIds
        })

        let walletModelIdsToDelete = existingWalletModelIds.subtracting(newWalletModelIds)
        let walletModelIdsToAdd = newWalletModelIds.subtracting(existingWalletModelIds)

        if walletModelIdsToAdd.isEmpty, walletModelIdsToDelete.isEmpty {
            if _walletModels.value == nil {
                // Emit initial list. Case with first card scan without derivations
                _walletModels.send([])
            }

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

        updateWalletModelsWithPerformanceTrackingIfNeeded(walletModels: walletModelsToAdd)

        existingWalletModels.append(contentsOf: walletModelsToAdd)

        log(walletModels: existingWalletModels)

        _walletModels.send(existingWalletModels)
    }

    private func updateWalletModelsWithPerformanceTrackingIfNeeded(walletModels: [any WalletModel]) {
        var token: PerformanceMetricToken?

        if shouldTrackWalletModelsUpdate, walletModels.isNotEmpty {
            shouldTrackWalletModelsUpdate = false
            token = PerformanceTracker.startTracking(metric: .totalBalanceLoaded(tokensCount: walletModels.count))
        }

        Task {
            await Self.updateAllInternal(silent: false, walletModels: walletModels)

            if walletModels.contains(where: \.state.isBlockchainUnreachable) {
                PerformanceTracker.endTracking(token: token, with: .failure)
            } else {
                PerformanceTracker.endTracking(token: token, with: .success)
            }
        }
    }

    /// Must be stateless, therefore it's static.
    private static func updateAllInternal(silent: Bool, walletModels: [any WalletModel]) async {
        // Even modern iOS devices, like iPhone 17 Pro/Pro Max, have at most 6 CPU cores
        // Therefore, n=5 is a reasonable limit for concurrent network requests (as for now)
        let maxConcurrentUpdates = 5
        let count = walletModels.count

        await withTaskGroup(of: Void.self) { group in
            for index in 0 ..< count {
                // Maintain a sliding window of concurrent updates with a maximum size of `maxConcurrentUpdates`
                if index >= maxConcurrentUpdates {
                    await group.next()
                }
                _ = group.addTaskUnlessCancelled {
                    await walletModels[index].update(silent: silent, features: .balances)
                }
            }
            await group.waitForAll()
        }
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
        await Self.updateAllInternal(silent: silent, walletModels: walletModels)
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
