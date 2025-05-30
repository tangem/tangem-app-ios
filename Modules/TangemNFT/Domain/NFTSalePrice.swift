//
//  NFTSale.swift
//  TangemNFT
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public struct NFTSalePrice: Sendable, Hashable {
    let last: Price
    let lowest: Price?
    let highest: Price?
}

// MARK: - Auxiliary types

public extension NFTSalePrice {
    struct Price: Sendable, Hashable {
        // [REDACTED_TODO_COMMENT]
        let value: /* Amount */ Decimal
    }
}
