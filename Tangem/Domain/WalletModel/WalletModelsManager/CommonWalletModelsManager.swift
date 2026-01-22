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
    private var updateAllSubscription: AnyCancellable?

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

        var subscription: AnyCancellable?
        subscription = walletModels
            .map { $0.update(silent: false) }
            .combineLatest()
            .sink { states in
                if states.contains(where: \.isBlockchainUnreachable) {
                    PerformanceTracker.endTracking(token: token, with: .failure)
                } else {
                    PerformanceTracker.endTracking(token: token, with: .success)
                }
                withExtendedLifetime(subscription) {}
            }
    }

    /// Must be stateless, therefore it's static.
    private static func updateAllInternal(silent: Bool, walletModels: [any WalletModel]) async {
        await TaskGroup.execute(items: walletModels) {
            await $0.update(silent: silent, features: .balances)
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

    func updateAll() {
        walletModels.forEach {
            $0.update(silent: false)
        }
    }

    func updateAll(silent: Bool, completion: @escaping () -> Void) {
        let publishers = walletModels.map {
            $0.update(silent: silent)
        }

        updateAllSubscription = Publishers
            .MergeMany(publishers)
            .collect(publishers.count)
            .mapToVoid()
            .receive(on: DispatchQueue.main)
            .receiveCompletion { _ in
                completion()
            }
    }
}

// MARK: - Convenience extensions

private extension CommonWalletModelsManager {
    func log(walletModels: [any WalletModel]) {
        AppLogger.info("✅ Actual List of WalletModels [\(walletModels.map(\.name))]")
    }

    func makeTargetDerivationPath(for blockchain: Blockchain) -> DerivationPath? {
        guard let derivationStyle else {
            return nil
        }

        guard let defaultPath = blockchain.derivationPath(for: derivationStyle) else {
            return nil
        }

        let helper = AccountDerivationPathHelper(blockchain: blockchain)
        return helper.makeDerivationPath(from: defaultPath, forAccountWithIndex: derivationIndex)
    }
}
