//
//  SendMainButtonType.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

enum SendMainButtonType {
    case next
    case `continue`
    case action
    case close
}

enum SendFlowActionType: Hashable {
    case send
    case stake
    case unstake
    case withdraw
    case claimRewards
    case restakeRewards

    var title: String {
        switch self {
        case .send: Localization.commonSend
        case .stake: Localization.commonStake
        case .unstake: Localization.commonUnstake
        case .withdraw: Localization.stakingWithdraw
        case .claimRewards: Localization.commonClaimRewards
        case .restakeRewards: Localization.commonClaimRewards // [REDACTED_TODO_COMMENT]
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

    var icon: MainButton.Icon? {
        switch self {
        case .action:
            .trailing(Assets.tangemIcon)
        default:
            nil
        }
    }
}
