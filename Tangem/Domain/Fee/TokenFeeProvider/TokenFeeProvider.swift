//
//  TokenFeeProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation

protocol TokenFeeProvider: FeeSelectorFeesProvider {
    func reloadFees(request: TokenFeeProviderFeeRequest)
}

struct TokenFeeProviderFeeRequest {
    let amount: Decimal
    let destination: String
    /// Sending token item
    let tokenItem: TokenItem
}
