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
    case action(SendFlowActionType)
    case close
}

enum SendFlowActionType: Hashable {
    case send
    case stake
    case unstake
    case claimRewards
    case restakeRewards

    var title: String {
        switch self {
        case .send: Localization.commonSend
        case .stake: Localization.commonStake
        case .unstake: Localization.commonUnstake
        case .claimRewards: Localization.commonClaimRewards
        case .restakeRewards: Localization.commonClaimRewards // [REDACTED_TODO_COMMENT]
        }
    }
}

extension SendMainButtonType {
    var title: String {
        switch self {
        case .next:
            Localization.commonNext
        case .continue:
            Localization.commonContinue
        case .action(let action):
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
