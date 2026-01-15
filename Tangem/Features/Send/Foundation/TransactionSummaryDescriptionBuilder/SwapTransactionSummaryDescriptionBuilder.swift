//
//  SwapTransactionSummaryDescriptionBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress
import TangemAssets

protocol SwapTransactionSummaryDescriptionBuilder: GenericTransactionSummaryDescriptionBuilder {
    func makeDescription(amount: Decimal?, fee: LoadableTokenFee, provider: ExpressProvider) -> AttributedString?
}

struct CommonSwapTransactionSummaryDescriptionBuilder {
    let sendTransactionSummaryDescriptionBuilder: SendTransactionSummaryDescriptionBuilder
}

// MARK: - SendTransactionSummaryDescriptionBuilder

extension CommonSwapTransactionSummaryDescriptionBuilder: SwapTransactionSummaryDescriptionBuilder {
    func makeDescription(amount: Decimal?, fee: LoadableTokenFee, provider: ExpressProvider) -> AttributedString? {
        let sendDescription: AttributedString? = {
            guard let amount = amount else {
                return nil
            }

            return sendTransactionSummaryDescriptionBuilder
                .makeDescription(amount: amount, fee: fee)
        }()

        let separator = makeAttributedString("\n")
        let swapDescription = provider.legalText(branch: .swap)

        switch (sendDescription, swapDescription) {
        case (.some(let sendDescription), .none):
            return sendDescription
        case (.none, .some(let swapDescription)):
            return swapDescription
        case (.some(let sendDescription), .some(let swapDescription)):
            return sendDescription + separator + swapDescription
        case (.none, .none):
            return .none
        }
    }
}
