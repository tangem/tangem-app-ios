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

    init(tokenItem: TokenItem) {
        self.tokenItem = tokenItem
    }
}

// MARK: - SendTransactionSummaryDescriptionBuilder

extension KoinosSendTransactionSummaryDescriptionBuilder: SendTransactionSummaryDescriptionBuilder {
    func makeDescription(amount: Decimal, fee: LoadableTokenFee) -> AttributedString? {
        guard let bsdkFee = fee.value.value else {
            return nil
        }

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
        let feeInFiatFormatted = feeFormatter.format(fee: bsdkFee.amount.value, tokenItem: fee.tokenItem)
        let attributedString = makeAttributedString(
            Localization.sendSummaryTransactionDescriptionNoFiatFee(totalInFiatFormatted, feeInFiatFormatted),
            richTexts: [totalInFiatFormatted]
        )

        return attributedString
    }
}
