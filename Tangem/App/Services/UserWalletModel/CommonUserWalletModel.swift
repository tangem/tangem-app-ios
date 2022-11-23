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
    private(set) var didPerformInitialUpdate = false
    private let walletListManager: WalletListManager

    private var reloadAllWalletModelsBag: AnyCancellable?

    convenience init(config: UserWalletConfig, userWallet: UserWallet) {
        let userTokenListManager = CommonUserTokenListManager(config: config, userWalletId: userWallet.userWalletId)
        let walletListManager = CommonWalletListManager(
            config: config,
            name: userWallet.name,
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

    func updateWalletModels() {
        // Update walletModel list for current storage state
        walletListManager.updateWalletModels()
    }

    func updateAndReloadWalletModels(silent: Bool, completion: @escaping () -> Void) {
        didPerformInitialUpdate = true

        updateWalletModels()

        print("*** updateAndReloadWalletModels", userWallet.userWalletId.hexString)

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

        updateAndReloadWalletModels()
    }

    func append(entries: [StorageEntry]) {
        userTokenListManager.update(.append(entries))

        updateAndReloadWalletModels()
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
