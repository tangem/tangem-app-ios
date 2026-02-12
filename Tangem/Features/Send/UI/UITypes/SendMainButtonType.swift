//
//  SendMainButtonType.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import TangemAssets
import TangemLocalization
import TangemUI

enum SendMainButtonType: Hashable {
    case next
    case `continue`
    case action
    case close
}

enum SendFlowActionType: Hashable {
    case send
    case swap
    case approve
    case stake
    case unstake
    case claimRewards
    case restakeRewards
    case withdraw
    case restake
    case claimUnstaked
    case unlockLocked
    case stakeLocked
    case vote
    case revoke
    case voteLocked
    case revote
    case rebond
    case migrate
    case onramp

    var title: String {
        switch self {
        case .send: Localization.commonSend
        case .swap: Localization.commonSwap
        case .approve: Localization.givePermissionTitle
        case .stake: Localization.commonStake
        case .unstake: Localization.commonUnstake
        case .claimRewards: Localization.commonClaimRewards
        case .restakeRewards: Localization.stakingRestakeRewards
        case .withdraw, .claimUnstaked: Localization.stakingWithdraw
        case .restake: Localization.stakingRestake
        case .unlockLocked: Localization.stakingUnlockedLocked
        case .stakeLocked: Localization.stakingStakeLocked
        case .vote: Localization.stakingVote
        case .revoke: Localization.stakingRevoke
        case .voteLocked: Localization.stakingVoteLocked
        case .revote: Localization.stakingRevote
        case .rebond: Localization.stakingRebond
        case .migrate: Localization.stakingMigrate
        case .onramp: Localization.commonBuy
        }
    }
}

extension SendMainButtonType {
    func title(action: SendFlowActionType) -> String {
        switch self {
        case .next:
            Localization.commonNext
        case .continue:
            Localization.commonContinue
        case .action:
            action.title
        case .close:
            Localization.commonClose
        }
    }

    func icon(action: SendFlowActionType, provider: TangemIconProvider) -> MainButton.Icon? {
        switch self {
        case .action where action == .onramp: nil
        case .action: provider.getMainButtonIcon()
        default: nil
        }
    }
}
