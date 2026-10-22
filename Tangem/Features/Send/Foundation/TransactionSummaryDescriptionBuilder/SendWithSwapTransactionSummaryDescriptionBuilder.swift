//
//  SendWithSwapTransactionSummaryDescriptionBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress

protocol SendWithSwapTransactionSummaryDescriptionBuilder: GenericTransactionSummaryDescriptionBuilder {
    func makeDescription(amount: Decimal?, fee: TokenFee, provider: ExpressProvider) -> AttributedString?
}

struct CommonSendWithSwapTransactionSummaryDescriptionBuilder {
    let swapTransactionSummaryDescriptionBuilder: SwapTransactionSummaryDescriptionBuilder
}

// MARK: - SendWithSwapTransactionSummaryDescriptionBuilder

extension CommonSendWithSwapTransactionSummaryDescriptionBuilder: SendWithSwapTransactionSummaryDescriptionBuilder {
    func makeDescription(amount: Decimal?, fee: TokenFee, provider: ExpressProvider) -> AttributedString? {
        swapTransactionSummaryDescriptionBuilder.makeDescription(amount: amount, fee: fee, provider: provider)
    }
}
