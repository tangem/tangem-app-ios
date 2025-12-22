//
//  TransactionViewIconViewData.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import TangemAssets

struct TransactionViewIconViewData: Hashable {
    let type: TransactionViewModel.TransactionType
    let status: TransactionViewModel.Status
    let isOutgoing: Bool

    var icon: Image {
        if status == .failed {
            return Assets.crossBig.image
        }
        switch type {
        case .approve, .yieldDeploy:
            return Assets.approve.image
        case .transfer, .swap, .operation, .unknownOperation, .tangemPay(.transfer), .yieldTopup, .yieldSend:
            return isOutgoing ? Assets.arrowUpMini.image : Assets.arrowDownMini.image
        case .stake, .vote, .restake:
            return Assets.TokenItemContextMenu.menuStaking.image
        case .unstake, .withdraw:
            return Assets.unstakedIcon.image
        case .claimRewards:
            return Assets.dollarMini.image
        case .tangemPay(.fee):
            return Assets.Visa.feeTransactionPercent.image
        case .tangemPay(.spend):
            return Assets.Visa.otherTransaction.image
        case .yieldReactivate:
            return Assets.YieldModule.yieldModeReactivate.image
        case .yieldEnter, .yieldEnterCoin:
            return Assets.YieldModule.yieldModeEnable.image
        case .yieldWithdraw, .yieldWithdrawCoin:
            return Assets.YieldModule.yieldModeDisable.image
        case .yieldInit:
            return Assets.YieldModule.yieldModeInit.image
        }
    }

    var iconColor: Color {
        switch status {
        case .inProgress:
            return Colors.Icon.accent
        case .confirmed:
            return Colors.Icon.informative
        case .failed, .undefined:
            return Colors.Icon.warning
        }
    }

    var iconBackgroundColor: Color {
        switch status {
        case .inProgress: return Colors.Icon.accent.opacity(0.1)
        case .confirmed: return Colors.Button.secondary
        case .failed, .undefined: return Colors.Icon.warning.opacity(0.1)
        }
    }
}
