//
//  JointAccountSendTransactionSummaryDescriptionBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

struct JointAccountSendTransactionSummaryDescriptionBuilder {
    private let tokenItem: TokenItem
    private let policy: JointAccountPolicy

    init(tokenItem: TokenItem, policy: JointAccountPolicy) {
        self.tokenItem = tokenItem
        self.policy = policy
    }
}

// MARK: - SendTransactionSummaryDescriptionBuilder

extension JointAccountSendTransactionSummaryDescriptionBuilder: SendTransactionSummaryDescriptionBuilder {
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
            Localization.jointAccountSendFooterText(
                totalInFiatFormatted,
                feeInFiatFormatted,
                policy.signersCount,
                policy.membersCount
            )
        )

        return attributedString
    }
}
