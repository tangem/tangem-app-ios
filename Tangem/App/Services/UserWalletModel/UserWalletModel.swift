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
    var walletListManager: WalletListManager { get }

    func updateUserWalletModel(with config: UserWalletConfig)

    func getWalletModels() -> [WalletModel]
    func subscribeToWalletModels() -> AnyPublisher<[WalletModel], Never>

    func getEntriesWithoutDerivation() -> [StorageEntry]
    func subscribeToEntriesWithoutDerivation() -> AnyPublisher<[StorageEntry], Never>

    func canManage(amountType: Amount.AmountType, blockchainNetwork: BlockchainNetwork) -> Bool
    func update(entries: [StorageEntry], result: @escaping (Result<UserTokenList, Error>) -> Void)
    func append(entries: [StorageEntry], result: @escaping (Result<UserTokenList, Error>) -> Void)
    func remove(item: CommonUserWalletModel.RemoveItem, completion: @escaping (Result<UserTokenList, Error>) -> Void)
    func clearRepository(result: @escaping (Result<UserTokenList, Error>) -> Void)

    func updateAllWalletModelsWithCallUpdateInWalletModel(showProgressLoading: Bool)
}
