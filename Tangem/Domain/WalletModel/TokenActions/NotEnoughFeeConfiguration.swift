//
//  NotEnoughFeeConfiguration.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemUI

struct NotEnoughFeeConfiguration: Hashable {
    let amountCurrencySymbol: String
    let amountCurrencyBlockchainName: String
    let transactionAmountTypeName: String
    let feeAmountTypeName: String
    let feeAmountTypeCurrencySymbol: String
    let feeTokenIconInfo: TokenIconInfo
    let networkName: String
    let currencyButtonTitle: String?
    let isFeeCurrencyPurchaseAllowed: Bool
    let feeCurrencyBalance: Decimal
}
