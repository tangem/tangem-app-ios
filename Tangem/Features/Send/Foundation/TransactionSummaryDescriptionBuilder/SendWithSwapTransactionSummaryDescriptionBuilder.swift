//
//  SendWithSwapTransactionSummaryDescriptionBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress
import TangemAssets

protocol SendWithSwapTransactionSummaryDescriptionBuilder: GenericTransactionSummaryDescriptionBuilder {
    func makeDescription(amount: Decimal?, fee: TokenFee, provider: ExpressProvider) -> AttributedString?
}

struct CommonSendWithSwapTransactionSummaryDescriptionBuilder {
    let sendTransactionSummaryDescriptionBuilder: SendTransactionSummaryDescriptionBuilder
    let swapTransactionSummaryDescriptionBuilder: SwapTransactionSummaryDescriptionBuilder
}

// MARK: - SendTransactionSummaryDescriptionBuilder

extension CommonSendWithSwapTransactionSummaryDescriptionBuilder: SendWithSwapTransactionSummaryDescriptionBuilder {
    func makeDescription(amount: Decimal?, fee: TokenFee, provider: ExpressProvider) -> AttributedString? {
        let sendDescription: AttributedString? = {
            guard let amount = amount else {
                return nil
            }

            return sendTransactionSummaryDescriptionBuilder
                .makeDescription(amount: amount, fee: fee)
        }()

        let swapDescription = swapTransactionSummaryDescriptionBuilder.makeDescription(provider: provider)

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
