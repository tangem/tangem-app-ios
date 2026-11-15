//
//  TokenFeeProviderID.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum TokenFeePayer: Hashable {
    case user
    case tangem
}

struct TokenFeeProviderID: Hashable {
    let feeTokenItem: TokenItem
    let payer: TokenFeePayer
}
