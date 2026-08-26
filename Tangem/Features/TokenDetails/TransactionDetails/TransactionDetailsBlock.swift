//
//  TransactionDetailsBlock.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemMacro

@RawCaseName
enum TransactionDetailsBlock: Identifiable {
    case tokens(TransactionDetailsTokensViewData)
    case yieldTokens(TransactionDetailsYieldTokensViewData)
    case statusBanner(TransactionDetailsStatusBannerViewData)
    case principalAmount(TransactionDetailsPrincipalAmountViewData)
    case counterparty(TransactionDetailsAddressViewData)
    case info(TransactionDetailsInfoSectionViewData)
    case action(TransactionDetailsActionButtonViewData)
    case rating(RatingViewModel)
}
