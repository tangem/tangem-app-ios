//
//  SwapTransactionSummaryDescriptionBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemExpress

protocol SwapTransactionSummaryDescriptionBuilder: GenericTransactionSummaryDescriptionBuilder {
    func makeDescription(provider: ExpressProvider) -> AttributedString?
}

struct CommonSwapTransactionSummaryDescriptionBuilder {}

// MARK: - SendTransactionSummaryDescriptionBuilder

extension CommonSwapTransactionSummaryDescriptionBuilder: SwapTransactionSummaryDescriptionBuilder {
    func makeDescription(provider: ExpressProvider) -> AttributedString? {
        let swapDescription = provider.legalText(branch: .swap)
        return swapDescription
    }
}
