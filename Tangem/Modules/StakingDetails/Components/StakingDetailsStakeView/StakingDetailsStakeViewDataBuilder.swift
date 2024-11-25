//
//  StakingDetailsStakeViewDataBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking
import SwiftUI

class StakingDetailsStakeViewDataBuilder {
    private lazy var balanceFormatter = BalanceFormatter()
    private lazy var percentFormatter = PercentFormatter()
    private lazy var dateFormatter = DateComponentsFormatter.staking()

    private let tokenItem: TokenItem

    init(tokenItem: TokenItem) {
        self.tokenItem = tokenItem
    }

    func mapToStakingDetailsStakeViewData(yield: YieldInfo, balance: StakingBalance, action: @escaping () -> Void) -> StakingDetailsStakeViewData {
        let validator = balance.validatorType.validator
        let inProgress = balance.inProgress

        let title: String = {
            switch balance.balanceType {
            case .rewards: Localization.stakingRewards
            case .locked: inProgress ? Localization.stakingUnlocking : Localization.stakingLocked
            case .warmup, .active, .pending: validator?.name ?? Localization.stakingValidator
            case .unbonding: Localization.stakingUnstaking
            case .unstaked: Localization.stakingUnstaked
            }
        }()

        let subtitle: StakingDetailsStakeViewData.SubtitleType? = {
            switch balance.balanceType {
            case .rewards: .none
            case .locked:
                .locked(hasVoteLocked: balance.actions.contains(where: { $0.type == .voteLocked }))
            case .unstaked: .withdraw
            case .warmup: .warmup(period: yield.warmupPeriod.formatted(formatter: dateFormatter))
            case .active, .pending:
                validator?.apr.map { .active(apr: percentFormatter.format($0, option: .staking)) }
            case .unbonding(let date):
                date.map { .unbonding(until: $0) } ?? .unbondingPeriod(period: yield.unbondingPeriod.formatted(formatter: dateFormatter))
            }
        }()

        let icon: StakingDetailsStakeViewData.IconType = {
            switch balance.balanceType {
            case .rewards, .warmup, .active, .pending:
                balance.validatorType == .disabled
                    ? .icon(
                        Assets.stakingIconFilled,
                        colors: .init(foreground: Colors.Icon.inactive, background: Colors.Icon.primary1)
                    )
                    : .image(url: validator?.iconURL)
            case .locked:
                .icon(
                    inProgress ? Assets.stakingUnlockingIcon : Assets.stakingLockIcon,
                    colors: .init(foreground: inProgress ? Colors.Icon.accent : Colors.Icon.informative)
                )
            case .unbonding: .icon(Assets.unstakedIcon, colors: .init(foreground: Colors.Icon.accent))
            case .unstaked: .icon(Assets.unstakedIcon, colors: .init(foreground: Colors.Icon.informative))
            }
        }()

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
            case .rewards, .warmup, .pending:
                return nil
            case .unbonding:
                return balance.actions.isEmpty ? nil : action
            case .active, .unstaked, .locked:
                return inProgress ? nil : action
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
