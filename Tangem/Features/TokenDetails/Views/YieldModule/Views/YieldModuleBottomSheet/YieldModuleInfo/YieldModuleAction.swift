//
//  YieldModuleAction.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemLocalization
import TangemAssets

enum YieldModuleAction {
    case stop(tokenName: String)
    case approve

    var title: String {
        switch self {
        case .stop:
            Localization.yieldModuleStopEarningSheetTitle
        case .approve:
            Localization.yieldModuleApproveSheetTitle
        }
    }

    var description: String {
        switch self {
        case .stop(let tokenName):
            Localization.yieldModuleStopEarningSheetDescription(tokenName)
        case .approve:
            Localization.yieldModuleApproveSheetSubtitle
        }
    }

    var icon: ImageType {
        switch self {
        case .approve:
            Assets.YieldModule.yieldModuleApprove
        case .stop:
            Assets.attentionHalo
        }
    }

    var buttonTitle: String {
        switch self {
        case .stop:
            return Localization.yieldModuleStopEarning
        case .approve:
            return Localization.commonConfirm
        }
    }
}
