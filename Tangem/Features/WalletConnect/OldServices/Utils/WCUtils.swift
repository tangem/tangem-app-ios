//
//  WCUtils.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import BlockchainSdk
import ReownWalletKit

enum WCUtils {
    static func makeBlockchainMeta(from wcBlockchain: WalletConnectUtils.Blockchain) -> BlockchainMeta? {
        guard let blockchain = WalletConnectBlockchainMapper.mapToDomain(wcBlockchain) else { return nil }
        return BlockchainMeta(from: blockchain)
    }
}
