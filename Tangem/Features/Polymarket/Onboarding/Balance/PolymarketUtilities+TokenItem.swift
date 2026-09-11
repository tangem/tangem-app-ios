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
    /// `id` is what prices it, not what it is: the collateral is its own contract, pegged to USDC, so the USDC
    /// quote is the rate that converts it into the selected fiat currency.
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
