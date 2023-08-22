//
//  StorageEntry.V3+.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

extension StorageEntry.V3.Entry {
    var isCustom: Bool { id == nil }

    var isToken: Bool { contractAddress != nil }

    @available(*, deprecated, message: "Doesn't take `SupportedBlockchains` into account and therefore shouldn't be used with Wallet 2.0")
    var walletModelId: WalletModel.ID {
        let converter = StorageEntriesConverter()

        if let token = converter.convertToToken(self) {
            return WalletModel.Id(blockchainNetwork: blockchainNetwork, amountType: .token(value: token)).id
        }

        return WalletModel.Id(blockchainNetwork: blockchainNetwork, amountType: .coin).id
    }
}
