//
//  StakingTransactionSummaryDescriptionBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking
import TangemLocalization

protocol StakingTransactionSummaryDescriptionBuilder {
    func makeDescription(amount: SendAmount, schedule: RewardScheduleType) -> String?
}

struct CommonStakingTransactionSummaryDescriptionBuilder {
    private let tokenItem: TokenItem
    private let balanceFormatter = BalanceFormatter()

    init(tokenItem: TokenItem) {
        self.tokenItem = tokenItem
    }
}

// MARK: - SendTransactionSummaryDescriptionBuilder

extension CommonStakingTransactionSummaryDescriptionBuilder: StakingTransactionSummaryDescriptionBuilder {
    func makeDescription(amount: SendAmount, schedule: RewardScheduleType) -> String? {
        guard let amountFiat = amount.fiat else {
            return nil
        }

        let amountFormattingOptions = BalanceFormattingOptions(
            minFractionDigits: BalanceFormattingOptions.defaultFiatFormattingOptions.minFractionDigits,
            maxFractionDigits: BalanceFormattingOptions.defaultFiatFormattingOptions.maxFractionDigits,
            formatEpsilonAsLowestRepresentableValue: true,
            roundingType: BalanceFormattingOptions.defaultFiatFormattingOptions.roundingType
        )

        let amountInFiatFormatted = balanceFormatter.formatFiatBalance(amountFiat, formattingOptions: amountFormattingOptions)

        let scheduleFormatted = schedule.formatted().lowercased()
        return Localization.stakingSummaryDescriptionText(amountInFiatFormatted, scheduleFormatted)
    }
}
