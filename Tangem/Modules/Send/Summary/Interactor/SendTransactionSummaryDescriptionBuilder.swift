//
//  SendTransactionSummaryDescriptionBuilder.swift
//  Tangem
//
//  Created by Sergey Balashov on 28.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct SendTransactionSummaryDescriptionBuilder {
    private let tokenItem: TokenItem
    private let feeTokenItem: TokenItem

    init(tokenItem: TokenItem, feeTokenItem: TokenItem) {
        self.tokenItem = tokenItem
        self.feeTokenItem = feeTokenItem
    }

    func makeDescription(amount: Decimal, fee: Decimal, isNoFiatFee: Bool) -> String? {
        let amountInFiat = tokenItem.id.flatMap { BalanceConverter().convertToFiat(amount, currencyId: $0) }
        let feeInFiat = isNoFiatFee ? 0 : feeTokenItem.id.flatMap { BalanceConverter().convertToFiat(fee, currencyId: $0) }

        let totalInFiat = [amountInFiat, feeInFiat].compactMap { $0 }.reduce(0, +)

        let formattingOptions = BalanceFormattingOptions(
            minFractionDigits: BalanceFormattingOptions.defaultFiatFormattingOptions.minFractionDigits,
            maxFractionDigits: BalanceFormattingOptions.defaultFiatFormattingOptions.maxFractionDigits,
            formatEpsilonAsLowestRepresentableValue: true,
            roundingType: BalanceFormattingOptions.defaultFiatFormattingOptions.roundingType
        )

        let formatter = BalanceFormatter()
        let totalInFiatFormatted = formatter.formatFiatBalance(totalInFiat, formattingOptions: formattingOptions)

        if isNoFiatFee {
            let feeFormatter = CommonFeeFormatter(balanceFormatter: formatter, balanceConverter: .init())
            return Localization.sendSummaryTransactionDescriptionNoFiatFee(
                totalInFiatFormatted,
                feeFormatter.format(fee: fee, tokenItem: feeTokenItem)
            )
        }

        return Localization.sendSummaryTransactionDescription(
            totalInFiatFormatted,
            formatter.formatFiatBalance(feeInFiat, formattingOptions: formattingOptions)
        )
    }
}
