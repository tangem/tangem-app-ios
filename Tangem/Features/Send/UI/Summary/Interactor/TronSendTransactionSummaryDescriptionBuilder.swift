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
    private let feeTokenItem: TokenItem

    init(tokenItem: TokenItem, feeTokenItem: TokenItem) {
        self.tokenItem = tokenItem
        self.feeTokenItem = feeTokenItem
    }
}

// MARK: - SendTransactionSummaryDescriptionBuilder

extension TronSendTransactionSummaryDescriptionBuilder: SendTransactionSummaryDescriptionBuilder {
    func makeDescription(transactionType: SendSummaryTransactionData) -> String? {
        guard case .send(let amount, let fee) = transactionType else {
            return nil
        }

        guard let feeParameters = fee.parameters as? TronFeeParameters else {
            AppLogger.error(error: "Fee parameters must be set for TronSendTransactionSummaryDescriptionBuilder")
            return nil
        }

        let amountInFiat = tokenItem.id.flatMap { BalanceConverter().convertToFiat(amount, currencyId: $0) }
        let feeInFiat = feeTokenItem.id.flatMap { BalanceConverter().convertToFiat(fee.amount.value, currencyId: $0) }
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

        return [prefix, suffix].joined(separator: ", ")
    }
}
