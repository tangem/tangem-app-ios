//
//  TangemPayUtilities+Extensions.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import BlockchainSdk
import TangemVisa

extension TangemPayUtilities {
    static var walletModelIdentifyingTokenItem: TokenItem {
        TokenItem.blockchain(
            BlockchainNetwork(
                TangemPayUtilities.blockchain,
                derivationPath: TangemPayUtilities.derivationPath
            )
        )
    }

    /// Hardcoded USDC token on visa blockchain network (currently - Polygon)
    static var usdcTokenItem: TokenItem {
        TokenItem.token(
            Token(
                name: "USDC",
                symbol: "USDC",
                contractAddress: "0x3c499c542cef5e3811e1192ce70d8cc03d5c3359",
                decimalCount: 6,
                id: "usd-coin",
                metadata: .fungibleTokenMetadata
            ),
            TangemPayUtilities.walletModelIdentifyingTokenItem.blockchainNetwork
        )
    }
}

extension Collection where Element == any WalletModel {
    var tangemPayWalletModel: (any WalletModel)? {
        first { $0.tokenItem == TangemPayUtilities.walletModelIdentifyingTokenItem }
    }
}
