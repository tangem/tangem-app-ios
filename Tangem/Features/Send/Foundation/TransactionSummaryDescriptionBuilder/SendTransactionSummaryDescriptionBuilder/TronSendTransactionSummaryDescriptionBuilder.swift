//
//  TronSendTransactionSummaryDescriptionBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import BlockchainSdk

struct TronSendTransactionSummaryDescriptionBuilder {
    private let tokenItem: TokenItem

    init(tokenItem: TokenItem) {
        self.tokenItem = tokenItem
    }
}

// MARK: - SendTransactionSummaryDescriptionBuilder

extension TronSendTransactionSummaryDescriptionBuilder: SendTransactionSummaryDescriptionBuilder {
    func makeDescription(amount: Decimal, fee: TokenFee) -> AttributedString? {
        guard let bsdkFee = fee.value.value, let feeParameters = bsdkFee.parameters as? TronFeeParameters else {
            AppLogger.error(error: "Fee parameters must be set for TronSendTransactionSummaryDescriptionBuilder")
            return nil
        }

        let amountInFiat = tokenItem.currencyId.flatMap { BalanceConverter().convertToFiat(amount, currencyId: $0) }
        let feeInFiat = fee.tokenItem.currencyId.flatMap { BalanceConverter().convertToFiat(bsdkFee.amount.value, currencyId: $0) }
        let totalInFiat = [amountInFiat, feeInFiat].compactMap { $0 }.reduce(0, +)

        let formattingOptions = BalanceFormattingOptions(
            minFractionDigits: BalanceFormattingOptions.defaultFiatFormattingOptions.minFractionDigits,
            maxFractionDigits: BalanceFormattingOptions.defaultFiatFormattingOptions.maxFractionDigits,
            formatEpsilonAsLowestRepresentableValue: true,
            roundingType: BalanceFormattingOptions.defaultFiatFormattingOptions.roundingType
        )

        let formatter = BalanceFormatter()
        let totalInFiatFormatted = formatter.formatFiatBalance(totalInFiat, formattingOptions: formattingOptions)

        let prefix = Localization.sendSummaryTransactionDescriptionPrefix(totalInFiatFormatted)
        let feeInFiatFormatted = formatter.formatFiatBalance(feeInFiat, formattingOptions: formattingOptions)

        let energySpentString = String(feeParameters.energySpent)

        let suffix = if feeParameters.energySpent > 0 {
            if feeParameters.energyFullyCoversFee {
                Localization.sendSummaryTransactionDescriptionSuffixFeeCovered(energySpentString)
            } else {
                Localization.sendSummaryTransactionDescriptionSuffixFeeReduced(energySpentString)
            }
        } else {
            Localization.sendSummaryTransactionDescriptionSuffixIncluding(feeInFiatFormatted)
        }

        let attributedString = makeAttributedString([prefix, suffix].joined(separator: ", "))
        return attributedString
    }
}
