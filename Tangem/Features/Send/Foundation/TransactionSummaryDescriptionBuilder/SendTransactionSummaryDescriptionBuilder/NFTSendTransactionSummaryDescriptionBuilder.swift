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
    private let feeTokenItem: TokenItem

    init(feeTokenItem: TokenItem) {
        self.feeTokenItem = feeTokenItem
    }
}

// MARK: - SendTransactionSummaryDescriptionBuilder protocol conformance

extension NFTSendTransactionSummaryDescriptionBuilder: SendTransactionSummaryDescriptionBuilder {
    func makeDescription(amount _: Decimal, fee: BSDKFee) -> AttributedString? {
        let feeInFiat = feeTokenItem.currencyId.flatMap { BalanceConverter().convertToFiat(fee.amount.value, currencyId: $0) }
        let feeFormatter = BalanceFormatter()
        let feeInFiatFormatted = feeFormatter.formatFiatBalance(feeInFiat, formattingOptions: .defaultFiatFormattingOptions)

        let attributedString = makeAttributedString(
            Localization.sendSummaryTransactionDescription(Localization.commonNft, feeInFiatFormatted),
            richTexts: [Localization.commonNft]
        )

        return attributedString
    }
}
