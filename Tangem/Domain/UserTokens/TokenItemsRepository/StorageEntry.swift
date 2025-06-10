//
//  StorageEntry.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import struct BlockchainSdk.Token

struct StorageEntry: Hashable {
    let blockchainNetwork: BlockchainNetwork
    var tokens: [Token]

    init(blockchainNetwork: BlockchainNetwork, tokens: [Token]) {
        self.blockchainNetwork = blockchainNetwork
        self.tokens = tokens
    }

    init(blockchainNetwork: BlockchainNetwork, token: Token?) {
        self.blockchainNetwork = blockchainNetwork

        if let token = token {
            tokens = [token]
        } else {
            tokens = []
        }
    }
}

extension StorageEntry {
    var walletModelIds: [WalletModelId] {
        let mainCoinId = WalletModelId(tokenItem: .blockchain(blockchainNetwork))
        let tokenCoinIds = tokens.map {
            WalletModelId(tokenItem: .token($0, blockchainNetwork))
        }
        return [mainCoinId] + tokenCoinIds
    }
}
