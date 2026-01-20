//
//  TokenFee.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct TokenFee: Hashable {
    let option: FeeOption
    let tokenItem: TokenItem
    let value: LoadingResult<BSDKFee, any Error>

    func hash(into hasher: inout Hasher) {
        hasher.combine(option)
        hasher.combine(tokenItem)
        hasher.combine("\(value)")
    }

    static func == (lhs: TokenFee, rhs: TokenFee) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
}
