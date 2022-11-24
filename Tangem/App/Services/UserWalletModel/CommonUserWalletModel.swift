//
//  UserWalletModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Combine
import BlockchainSdk

class CommonUserWalletModel {
    private(set) var userWallet: UserWallet
    private var config: UserWalletConfig

    /// Public until managers factory
    let userTokenListManager: UserTokenListManager
    private let walletListManager: WalletListManager

    private var didPerformInitialUpdate = false
    private var reloadAllWalletModelsBag: AnyCancellable?

    init(config: UserWalletConfig, userWallet: UserWallet) {
        self.config = config
        self.userWallet = userWallet

        userTokenListManager = CommonUserTokenListManager(config: config, userWalletId: userWallet.userWalletId)
        walletListManager = CommonWalletListManager(
            config: config,
            userTokenListManager: userTokenListManager
        )
    }
}

// MARK: - UserWalletModel

extension CommonUserWalletModel: UserWalletModel {
    func updateUserWallet(_ userWallet: UserWallet) {
        print("🔄 Updating UserWalletModel with new userWalletId")
        self.userWallet = userWallet
        userTokenListManager.update(userWalletId: userWallet.userWalletId)
    }

    func updateUserWalletModel(with config: UserWalletConfig) {
        print("🔄 Updating UserWalletModel with new config")
        self.config = config
        walletListManager.update(config: config)
    }

    func getSavedEntries() -> [StorageEntry] {
        userTokenListManager.getEntriesFromRepository()
    }

    func getWalletModels() -> [WalletModel] {
        walletListManager.getWalletModels()
    }

    func subscribeToWalletModels() -> AnyPublisher<[WalletModel], Never> {
        walletListManager.subscribeToWalletModels()
    }

    func getEntriesWithoutDerivation() -> [StorageEntry] {
        walletListManager.getEntriesWithoutDerivation()
    }

    func subscribeToEntriesWithoutDerivation() -> AnyPublisher<[StorageEntry], Never> {
        walletListManager.subscribeToEntriesWithoutDerivation()
    }

    func initialUpdate() {
        /// It's used to check if the storage needs to be updated when the user adds a new wallet to saved wallets.
        if config.hasFeature(.tokenSynchronization),
           !userTokenListManager.didPerformInitialLoading {
            userTokenListManager.updateLocalRepositoryFromServer { [weak self] _ in
                self?.updateAndReloadWalletModels()
            }
        } else if !didPerformInitialUpdate {
            updateAndReloadWalletModels()
        } else {
            print("Initial update has been performed")
        }
    }

    func updateWalletModels() {
        // Update walletModel list for current storage state
        walletListManager.updateWalletModels()
    }

    func updateAndReloadWalletModels(silent: Bool, completion: @escaping () -> Void) {
        didPerformInitialUpdate = true

        updateWalletModels()

        reloadAllWalletModelsBag = walletListManager
            .reloadWalletModels(silent: silent)
            .receive(on: RunLoop.main)
            .receiveCompletion { _ in
                completion()
            }
    }

    func canManage(amountType: Amount.AmountType, blockchainNetwork: BlockchainNetwork) -> Bool {
        walletListManager.canManage(amountType: amountType, blockchainNetwork: blockchainNetwork)
    }

    func update(entries: [StorageEntry]) {
        userTokenListManager.update(.rewrite(entries))
    }

    func append(entries: [StorageEntry]) {
        userTokenListManager.update(.append(entries))
    }

    func remove(item: RemoveItem) {
        guard walletListManager.canRemove(amountType: item.amount, blockchainNetwork: item.blockchainNetwork) else {
            assertionFailure("\(item.blockchainNetwork.blockchain) can't be remove")
            return
        }

        switch item.amount {
        case .coin:
            removeBlockchain(item.blockchainNetwork)
        case let .token(token):
            removeToken(token, in: item.blockchainNetwork)
        case .reserve: break
        }
    }
}

// MARK: - Wallet models Operations

private extension CommonUserWalletModel {
    func removeBlockchain(_ network: BlockchainNetwork) {
        userTokenListManager.update(.removeBlockchain(network))
        walletListManager.updateWalletModels()
    }

    func removeToken(_ token: Token, in network: BlockchainNetwork) {
        userTokenListManager.update(.removeToken(token, in: network))
        walletListManager.removeToken(token, blockchainNetwork: network)
        walletListManager.updateWalletModels()
    }
}

extension CommonUserWalletModel {
    struct RemoveItem {
        let amount: Amount.AmountType
        let blockchainNetwork: BlockchainNetwork
    }
}
