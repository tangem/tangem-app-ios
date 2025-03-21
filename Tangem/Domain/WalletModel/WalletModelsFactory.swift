//
//  WalletModelsFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

protocol WalletModelsFactory {
    func makeWalletModels(from walletManager: WalletManager) -> [any WalletModel]
    func makeWalletModels(for types: [Amount.AmountType], walletManager: WalletManager) -> [any WalletModel]
}
