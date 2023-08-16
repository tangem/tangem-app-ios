//
//  StorageEntry+WalletModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

extension StorageEntry {
    var walletModelIds: [WalletModel.ID] {
        let mainCoinId = WalletModel.Id(blockchainNetwork: blockchainNetwork, amountType: .coin).id
        let tokenCoinIds = tokens.map { token in
            return WalletModel.Id(
                blockchainNetwork: blockchainNetwork,
                amountType: .token(value: token)
            ).id
        }
        return [mainCoinId] + tokenCoinIds
    }
}
