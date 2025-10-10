//
//  KoinosSendTransactionSummaryDescriptionBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

struct KoinosSendTransactionSummaryDescriptionBuilder {
    private let tokenItem: TokenItem
    private let feeTokenItem: TokenItem

    init(tokenItem: TokenItem, feeTokenItem: TokenItem) {
        self.tokenItem = tokenItem
        self.feeTokenItem = feeTokenItem
    }
}

// MARK: - SendTransactionSummaryDescriptionBuilder

extension KoinosSendTransactionSummaryDescriptionBuilder: SendTransactionSummaryDescriptionBuilder {
    func makeDescription(amount: Decimal, fee: BSDKFee) -> AttributedString? {
        let amountInFiat = tokenItem.currencyId.flatMap { BalanceConverter().convertToFiat(amount, currencyId: $0) }

        let formattingOptions = BalanceFormattingOptions(
            minFractionDigits: BalanceFormattingOptions.defaultFiatFormattingOptions.minFractionDigits,
            maxFractionDigits: BalanceFormattingOptions.defaultFiatFormattingOptions.maxFractionDigits,
            formatEpsilonAsLowestRepresentableValue: true,
            roundingType: BalanceFormattingOptions.defaultFiatFormattingOptions.roundingType
        )

        let formatter = BalanceFormatter()
        let feeFormatter = CommonFeeFormatter(balanceFormatter: formatter, balanceConverter: .init())

        let totalInFiatFormatted = formatter.formatFiatBalance(amountInFiat, formattingOptions: formattingOptions)
        let feeInFiatFormatted = feeFormatter.format(fee: fee.amount.value, tokenItem: feeTokenItem)
        let attributedString = makeAttributedString(
            Localization.sendSummaryTransactionDescriptionNoFiatFee(totalInFiatFormatted, feeInFiatFormatted),
            richTexts: [totalInFiatFormatted]
        )

        return attributedString
    }
}
