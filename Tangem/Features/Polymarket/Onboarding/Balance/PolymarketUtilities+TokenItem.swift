//
//  PolymarketUtilities+TokenItem.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemPolymarket

extension PolymarketUtilities {
    static var collateralTokenItem: TokenItem {
        TokenItem.token(
            Token(
                name: "Polymarket USD",
                symbol: "pUSD",
                contractAddress: PolymarketCollateral.contractAddress,
                decimalCount: PolymarketCollateral.decimalCount,
                id: "usd-coin",
                metadata: .fungibleTokenMetadata
            ),
            BlockchainNetwork(blockchain, derivationPath: derivationPath)
        )
    }
}
