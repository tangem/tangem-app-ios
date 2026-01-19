//
//  SendTransactionSummaryDescriptionBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import TangemAssets

protocol SendTransactionSummaryDescriptionBuilder: GenericTransactionSummaryDescriptionBuilder {
    func makeDescription(amount: Decimal, fee: TokenFee) -> AttributedString?
}

struct CommonSendTransactionSummaryDescriptionBuilder {
    private let tokenItem: TokenItem

    init(tokenItem: TokenItem) {
        self.tokenItem = tokenItem
    }
}

// MARK: - SendTransactionSummaryDescriptionBuilder

extension CommonSendTransactionSummaryDescriptionBuilder: SendTransactionSummaryDescriptionBuilder {
    func makeDescription(amount: Decimal, fee: TokenFee) -> AttributedString? {
        let amountInFiat = tokenItem.currencyId.flatMap { BalanceConverter().convertToFiat(amount, currencyId: $0) }
        let feeInFiat = fee.tokenItem.currencyId.flatMap { currencyId in
            fee.value.value.flatMap { BalanceConverter().convertToFiat($0.amount.value, currencyId: currencyId) }
        }

        var totalInFiat: Decimal? = nil

        if let amountInFiat, let feeInFiat {
            totalInFiat = amountInFiat + feeInFiat
        }

        let formattingOptions = BalanceFormattingOptions(
            minFractionDigits: BalanceFormattingOptions.defaultFiatFormattingOptions.minFractionDigits,
            maxFractionDigits: BalanceFormattingOptions.defaultFiatFormattingOptions.maxFractionDigits,
            formatEpsilonAsLowestRepresentableValue: true,
            roundingType: BalanceFormattingOptions.defaultFiatFormattingOptions.roundingType
        )

        let formatter = BalanceFormatter()
        let totalInFiatFormatted = formatter.formatFiatBalance(totalInFiat, formattingOptions: formattingOptions)
        let feeInFiatFormatted = formatter.formatFiatBalance(feeInFiat, formattingOptions: formattingOptions)
        let attributedString = makeAttributedString(
            Localization.sendSummaryTransactionDescription(totalInFiatFormatted, feeInFiatFormatted),
            richTexts: [totalInFiatFormatted]
        )

        return attributedString
    }
}
