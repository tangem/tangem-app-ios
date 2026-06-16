//
//  NFTSendTransactionSummaryDescriptionBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

struct NFTSendTransactionSummaryDescriptionBuilder {}

// MARK: - SendTransactionSummaryDescriptionBuilder protocol conformance

extension NFTSendTransactionSummaryDescriptionBuilder: SendTransactionSummaryDescriptionBuilder {
    func makeDescription(amount _: Decimal, fee: TokenFee) -> AttributedString? {
        let feeInFiat = fee.tokenItem.currencyId.flatMap { currencyId in
            fee.value.value.flatMap { BalanceConverter().convertToFiat($0.amount.value, currencyId: currencyId) }
        }

        let feeFormatter = BalanceFormatter()
        let feeInFiatFormatted = feeFormatter.formatFiatBalance(feeInFiat, formattingOptions: .defaultFiatFormattingOptions)

        let attributedString = makeAttributedString(
            Localization.sendSummaryTransactionDescription(Localization.commonNft, feeInFiatFormatted),
            richTexts: [Localization.commonNft]
        )

        return attributedString
    }
}
