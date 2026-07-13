//
//  ExpressRestriction.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public enum ExpressRestriction {
    case tooSmallAmount(_ minAmount: Decimal, currencySymbol: String)
    case tooBigAmount(_ maxAmount: Decimal, currencySymbol: String)
    case approveTransactionInProgress(spender: String)
    case insufficientBalance(_ requiredAmount: Decimal)
    case feeCurrencyHasZeroBalance(isFeeCurrency: Bool)
    case feeCurrencyInsufficientBalanceForTxValue(_ estimatedTxValue: Decimal, isFeeCurrency: Bool)
    /// The swap can't be covered once the network fee is applied, and that fee is paid via gasless (in the source
    /// token itself). The blocker is the fee, not the swap amount, so it must surface as a fee shortfall.
    case gaslessFeeShortfall
}
