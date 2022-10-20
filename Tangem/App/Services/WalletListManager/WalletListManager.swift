//
//  WalletListManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import BlockchainSdk
import Combine

protocol WalletListManager {
    func update(config: UserWalletConfig)

    func getWalletModels() -> [WalletModel]
    func subscribeToWalletModels() -> AnyPublisher<[WalletModel], Never>

    func getEntriesWithoutDerivation() -> [StorageEntry]
    func subscribeToEntriesWithoutDerivation() -> AnyPublisher<[StorageEntry], Never>

    /// Check new tokens in the respository and add if needed
    func updateWalletModels()

    /// Call method update in every wallet model
    func reloadWalletModels(silent: Bool) -> AnyPublisher<Void, Never>

    func canManage(amountType: Amount.AmountType, blockchainNetwork: BlockchainNetwork) -> Bool
    func canRemove(amountType: Amount.AmountType, blockchainNetwork: BlockchainNetwork) -> Bool

    func removeToken(_ token: Token, blockchainNetwork: BlockchainNetwork)
}
