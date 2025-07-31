//
//  SwapTransactionSummaryDescriptionBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress

protocol SwapTransactionSummaryDescriptionBuilder {
    func makeDescription(provider: ExpressProvider) -> AttributedString?
}

struct CommonSwapTransactionSummaryDescriptionBuilder {}

// MARK: - SendTransactionSummaryDescriptionBuilder

extension CommonSwapTransactionSummaryDescriptionBuilder: SwapTransactionSummaryDescriptionBuilder {
    func makeDescription(provider: ExpressProvider) -> AttributedString? {
        return provider.legalText(branch: .onramp)
    }
}
