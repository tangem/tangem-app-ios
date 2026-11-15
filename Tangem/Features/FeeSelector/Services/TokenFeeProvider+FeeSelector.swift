//
//  TokenFeeProvider+FeeSelector.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension TokenFeeProvider {
    var feeSelectorTitle: String {
        switch payer {
        case .user:
            return feeTokenItem.name
        case .tangem:
            return "SmartGas \(feeTokenItem.currencySymbol)"
        }
    }

    var feeSelectorAccessibilitySymbol: String {
        switch payer {
        case .user:
            return feeTokenItem.currencySymbol
        case .tangem:
            return feeSelectorTitle
        }
    }
}
