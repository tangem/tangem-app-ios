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
    /// How many of a joint account's members have answered. Tinted rather than plain: the count is what the
    /// operation is stuck on, not just another detail of it.
    case signatures(TransactionDetailsSignaturesViewData)
    /// A closing line about what happens next, centred under whatever it explains.
    case caption(String)
}
