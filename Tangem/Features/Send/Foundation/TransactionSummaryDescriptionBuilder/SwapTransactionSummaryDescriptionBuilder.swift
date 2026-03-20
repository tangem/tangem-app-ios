//
//  SwapTransactionSummaryDescriptionBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemExpress

protocol SwapTransactionSummaryDescriptionBuilder: GenericTransactionSummaryDescriptionBuilder {
    func makeDescription(amount: Decimal?, fee: TokenFee, provider: ExpressProvider) -> AttributedString?
}

struct CommonSwapTransactionSummaryDescriptionBuilder {
    let sendTransactionSummaryDescriptionBuilder: SendTransactionSummaryDescriptionBuilder
}

// MARK: - SwapTransactionSummaryDescriptionBuilder

extension CommonSwapTransactionSummaryDescriptionBuilder: SwapTransactionSummaryDescriptionBuilder {
    func makeDescription(amount: Decimal?, fee: TokenFee, provider: ExpressProvider) -> AttributedString? {
        let sendDescription: AttributedString? = {
            guard let amount else {
                return nil
            }

            return sendTransactionSummaryDescriptionBuilder
                .makeDescription(amount: amount, fee: fee)
        }()

        let swapDescription = provider.legalText(branch: .swap)

        switch (sendDescription, swapDescription) {
        case (.some(let sendDescription), .none):
            return sendDescription
        case (.none, .some(let swapDescription)):
            return swapDescription
        case (.some(let sendDescription), .some(let swapDescription)):
            let separator = makeAttributedString("\n")
            return sendDescription + separator + swapDescription
        case (.none, .none):
            return .none
        }
    }
}
