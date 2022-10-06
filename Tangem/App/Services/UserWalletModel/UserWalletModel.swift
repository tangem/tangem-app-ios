//
//  UserWalletModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import BlockchainSdk
import Combine

protocol UserWalletModel {
    /// Public until managers factory
    var userTokenListManager: UserTokenListManager { get }

    var userWallet: UserWallet { get }

    func updateUserWalletModel(with config: UserWalletConfig)
    func updateUserWallet(_ userWallet: UserWallet)

    func getWalletModels() -> [WalletModel]
    func subscribeToWalletModels() -> AnyPublisher<[WalletModel], Never>

    func getSavedEntries() -> [StorageEntry]
    func getEntriesWithoutDerivation() -> [StorageEntry]
    func subscribeToEntriesWithoutDerivation() -> AnyPublisher<[StorageEntry], Never>

    func canManage(amountType: Amount.AmountType, blockchainNetwork: BlockchainNetwork) -> Bool
    func update(entries: [StorageEntry], completion: @escaping () -> Void)
    func append(entries: [StorageEntry], completion: @escaping () -> Void)
    func remove(item: CommonUserWalletModel.RemoveItem, completion: @escaping () -> Void)

    func updateAndReloadWalletModels(completion: @escaping () -> Void)
}

extension UserWalletModel {
    func updateAndReloadWalletModels() {
        updateAndReloadWalletModels(completion: {})
    }
}
