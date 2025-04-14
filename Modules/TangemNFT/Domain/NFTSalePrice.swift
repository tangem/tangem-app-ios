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
    public let last: Price
    public let lowest: Price?
    public let highest: Price?
}

// MARK: - Auxiliary types

public extension NFTSalePrice {
    struct Price: Sendable {
        // [REDACTED_TODO_COMMENT]
        public let value: /* Amount */ Decimal
    }
}
