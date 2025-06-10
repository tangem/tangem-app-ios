//
//  NFTSale.swift
//  TangemNFT
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

// [REDACTED_TODO_COMMENT]
public struct NFTSalePrice: Sendable {
    let last: Price
    let lowest: Price?
    let highest: Price?
}

// MARK: - Auxiliary types

public extension NFTSalePrice {
    struct Price: Sendable {
        // [REDACTED_TODO_COMMENT]
        let value: /* Amount */ Decimal
    }
}
