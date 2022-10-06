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
    /// Public until managers factory
    let userTokenListManager: UserTokenListManager
    private(set) var userWallet: UserWallet
    private let walletListManager: WalletListManager

    private var reloadAllWalletModelsBag: AnyCancellable?

    convenience init(config: UserWalletConfig, userWallet: UserWallet) {
        let userTokenListManager = CommonUserTokenListManager(config: config, userWalletId: userWallet.userWalletId)
        let walletListManager = CommonWalletListManager(
            config: config,
            userTokenListManager: userTokenListManager
        )

        self.init(
            userTokenListManager: userTokenListManager,
            walletListManager: walletListManager,
            userWallet: userWallet
        )
    }

    init(
        userTokenListManager: UserTokenListManager,
        walletListManager: WalletListManager,
        userWallet: UserWallet
    ) {
        self.userTokenListManager = userTokenListManager
        self.walletListManager = walletListManager
        self.userWallet = userWallet
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

    func updateAndReloadWalletModels(completion: @escaping () -> Void) {
        // Update walletModel list for current storage state
        walletListManager.updateWalletModels()

        reloadAllWalletModelsBag = walletListManager
            .reloadWalletModels()
            .receive(on: RunLoop.main)
            .receiveCompletion { _ in
                completion()
            }
    }

    func canManage(amountType: Amount.AmountType, blockchainNetwork: BlockchainNetwork) -> Bool {
        walletListManager.canManage(amountType: amountType, blockchainNetwork: blockchainNetwork)
    }

    func update(entries: [StorageEntry], completion: @escaping () -> Void) {
        userTokenListManager.update(.rewrite(entries), completion: completion)

        updateAndReloadWalletModels()
    }

    func append(entries: [StorageEntry], completion: @escaping () -> Void) {
        userTokenListManager.update(.append(entries), completion: completion)

        updateAndReloadWalletModels()
    }

    func remove(item: RemoveItem, completion: @escaping () -> Void) {
        guard walletListManager.canRemove(amountType: item.amount, blockchainNetwork: item.blockchainNetwork) else {
            assertionFailure("\(item.blockchainNetwork.blockchain) can't be remove")
            return
        }

        switch item.amount {
        case .coin:
            removeBlockchain(item.blockchainNetwork, completion: completion)
        case let .token(token):
            removeToken(token, in: item.blockchainNetwork, completion: completion)
        case .reserve: break
        }
    }
}

// MARK: - Wallet models Operations

private extension CommonUserWalletModel {
    func removeBlockchain(_ network: BlockchainNetwork, completion: @escaping () -> Void) {
        userTokenListManager.update(.removeBlockchain(network), completion: completion)
        walletListManager.updateWalletModels()
    }

    func removeToken(_ token: Token, in network: BlockchainNetwork, completion: @escaping () -> Void) {
        userTokenListManager.update(.removeToken(token, in: network), completion: completion)
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
