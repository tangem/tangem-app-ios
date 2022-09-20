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

    func setUserWallet(_ userWallet: UserWallet)

    func updateUserWalletModel(with config: UserWalletConfig)

    func getWalletModels() -> [WalletModel]
    func subscribeToWalletModels() -> AnyPublisher<[WalletModel], Never>

    func getEntriesWithoutDerivation() -> [StorageEntry]
    func subscribeToEntriesWithoutDerivation() -> AnyPublisher<[StorageEntry], Never>

    func canManage(amountType: Amount.AmountType, blockchainNetwork: BlockchainNetwork) -> Bool
    func update(entries: [StorageEntry], result: @escaping (Result<UserTokenList, Error>) -> Void)
    func append(entries: [StorageEntry], result: @escaping (Result<UserTokenList, Error>) -> Void)
    func remove(item: CommonUserWalletModel.RemoveItem, result: @escaping (Result<UserTokenList, Error>) -> Void)
    func clearRepository(result: @escaping (Result<UserTokenList, Error>) -> Void)

    func updateAndReloadWalletModels(completion: @escaping () -> Void)
}

extension UserWalletModel {
    func updateAndReloadWalletModels() {
        updateAndReloadWalletModels(completion: {})
    }
}
