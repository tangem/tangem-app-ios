//
//  TokenFeeItem.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

typealias TokenFeeItem = TokenItem

typealias TokenFeeItemsList = [TokenFeeItem]

extension TokenFeeItemsList {
    var hasMultipleTokens: Bool { count > 1 }
}
