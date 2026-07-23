//
//  StakingAccessibilityIdentifiers.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public enum StakingAccessibilityIdentifiers {
    /// Main screen elements
    public static let title = "stakingTitle"
    public static let stakeButton = "stakingStakeButton"

    /// Staking Details Screen elements
    public static let annualPercentageRateValue = "stakingAnnualPercentageRateValue"
    public static let availableValue = "stakingAvailableValue"
    public static let unbondingPeriodValue = "stakingUnbondingPeriodValue"
    public static let rewardClaimingValue = "stakingRewardClaimingValue"
    public static let rewardScheduleValue = "stakingRewardScheduleValue"

    /// "Your stakes" section
    public static let yourStakesHeader = "stakingYourStakesHeader"
    public static let activeStakeRow = "stakingActiveStakeRow"
    public static let unstakingStakeRow = "stakingUnstakingStakeRow"
    public static let withdrawStakeRow = "stakingWithdrawStakeRow"

    /// Rewards section
    public static let rewardClaimBlock = "stakingRewardClaimBlock"
    public static let noRewardsToClaim = "stakingNoRewardsToClaim"

    /// Staking action notifications
    public static let unstakeNotification = "stakingUnstakeNotification"
    public static let withdrawNotification = "stakingWithdrawNotification"
    public static let claimRewardsNotification = "stakingClaimRewardsNotification"
}
