//
//  StakingValidatorRewardRateFormatter.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemStaking
import TangemLocalization

struct StakingValidatorRewardRateFormatter {
    private let percentFormatter = PercentFormatter()

    func title(rewardType: RewardType, type: TitleType) -> String {
        switch (rewardType, type) {
        case (.apr, .short): Localization.stakingDetailsApr
        case (.apr, .full): Localization.stakingDetailsAnnualPercentageRate
        case (.apy, .short): Localization.stakingDetailsApy
        case (.apy, .full): Localization.stakingDetailsAnnualPercentageYield
        }
    }

    func percent(rewardRate: Decimal) -> String {
        percentFormatter.format(rewardRate, option: .staking)
    }

    func format(validator: ValidatorInfo, type: TitleType) -> String {
        let prefix = title(rewardType: validator.rewardType, type: type)
        return "\(prefix) \(percent(rewardRate: validator.rewardRate))"
    }
}

extension StakingValidatorRewardRateFormatter {
    enum TitleType: Hashable {
        /// Abbreviation (APR)
        case short
        /// Full (Annual percentage rate)
        case full
    }
}
