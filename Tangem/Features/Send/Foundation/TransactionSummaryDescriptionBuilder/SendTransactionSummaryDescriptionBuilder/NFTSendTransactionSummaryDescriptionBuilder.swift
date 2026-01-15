//
//  NFTSendTransactionSummaryDescriptionBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

struct NFTSendTransactionSummaryDescriptionBuilder {
    init() {}
}

// MARK: - SendTransactionSummaryDescriptionBuilder protocol conformance

extension NFTSendTransactionSummaryDescriptionBuilder: SendTransactionSummaryDescriptionBuilder {
    func makeDescription(amount _: Decimal, fee: TokenFee) -> AttributedString? {
        guard let bsdkFee = fee.value.value else {
            return nil
        }

        let feeInFiat = fee.tokenItem.currencyId.flatMap { BalanceConverter().convertToFiat(bsdkFee.amount.value, currencyId: $0) }
        let feeFormatter = BalanceFormatter()
        let feeInFiatFormatted = feeFormatter.formatFiatBalance(feeInFiat, formattingOptions: .defaultFiatFormattingOptions)

        let attributedString = makeAttributedString(
            Localization.sendSummaryTransactionDescription(Localization.commonNft, feeInFiatFormatted),
            richTexts: [Localization.commonNft]
        )

        return attributedString
    }
}
