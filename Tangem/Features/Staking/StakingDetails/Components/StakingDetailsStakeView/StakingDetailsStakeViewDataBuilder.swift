//
//  StakingDetailsStakeViewDataBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import TangemAssets
import TangemStaking
import SwiftUI

class StakingDetailsStakeViewDataBuilder {
    private lazy var balanceFormatter = BalanceFormatter()
    private lazy var rewardRateFormatter = StakingTargetRewardRateFormatter()
    private lazy var dateFormatter = DateComponentsFormatter.staking()

    private let tokenItem: TokenItem

    init(tokenItem: TokenItem) {
        self.tokenItem = tokenItem
    }

    func mapToStakingDetailsStakeViewData(yield: StakingYieldInfo, balance: StakingBalance, action: @escaping () -> Void) -> StakingDetailsStakeViewData {
        let target = balance.targetType.target
        let inProgress = balance.inProgress

        let title: String = switch balance.balanceType {
        case .rewards: Localization.stakingRewards
        case .locked: inProgress ? Localization.stakingUnlocking : Localization.stakingLocked
        case .warmup, .active, .pending: target?.name ?? Localization.stakingValidator
        case .unbonding: Localization.stakingUnstaking
        case .unstaked: Localization.stakingUnstaked
        }

        let subtitle: StakingDetailsStakeViewData.SubtitleType? = switch balance.balanceType {
        case .rewards: .none
        case .locked:
            .locked(hasVoteLocked: balance.actions.contains(where: { $0.type == .voteLocked }))
        case .unstaked: .withdraw
        case .warmup: .warmup(period: yield.warmupPeriod.formatted(formatter: dateFormatter))
        case .active, .pending:
            target.map {
                .active(
                    type: rewardRateFormatter.title(rewardType: $0.rewardType, type: .short),
                    rate: rewardRateFormatter.percent(rewardRate: $0.rewardRate)
                )
            }
        case .unbonding(let date):
            date.map { .unbonding(until: $0) } ?? .unbondingPeriod(period: yield.unbondingPeriod.formatted(formatter: dateFormatter))
        }

        let icon: StakingDetailsStakeViewData.IconType = switch balance.balanceType {
        case .rewards, .warmup, .active, .pending:
            balance.targetType == .disabled
                ? .icon(
                    Assets.stakingIconFilled,
                    colors: .init(foreground: Colors.Icon.inactive, background: Colors.Icon.primary1)
                )
                : .image(url: target?.iconURL)
        case .locked:
            .icon(
                inProgress ? Assets.stakingUnlockingIcon : Assets.stakingLockIcon,
                colors: .init(foreground: inProgress ? Colors.Icon.accent : Colors.Icon.informative)
            )
        case .unbonding: .icon(Assets.unstakedIcon, colors: .init(foreground: Colors.Icon.accent))
        case .unstaked: .icon(Assets.unstakedIcon, colors: .init(foreground: Colors.Icon.informative))
        }

        let balanceCryptoFormatted = balanceFormatter.formatCryptoBalance(
            balance.amount,
            currencyCode: tokenItem.currencySymbol
        )
        let balanceFiat = tokenItem.currencyId.flatMap {
            BalanceConverter().convertToFiat(balance.amount, currencyId: $0)
        }
        let balanceFiatFormatted = balanceFormatter.formatFiatBalance(balanceFiat)

        let action: (() -> Void)? = {
            switch balance.balanceType {
            case .rewards, .unbonding, .pending: return nil
            case .active where inProgress: return nil
            case .active: return action
            case .unstaked, .locked, .warmup: return inProgress || balance.actions.isEmpty ? nil : action
            }
        }()

        return StakingDetailsStakeViewData(
            title: title,
            icon: icon,
            inProgress: inProgress,
            subtitleType: subtitle,
            balance: .init(crypto: balanceCryptoFormatted, fiat: balanceFiatFormatted),
            action: action
        )
    }
}

extension StakingDetailsStakeViewData {
    var priority: Int {
        switch subtitleType {
        case .none: -10
        case .warmup: -2
        case .locked: -1
        case .active: 0
        case .unbonding, .unbondingPeriod: 1
        case .withdraw: 2
        }
    }
}
