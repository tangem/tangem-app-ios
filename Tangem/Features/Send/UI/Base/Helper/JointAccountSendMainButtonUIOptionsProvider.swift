//
//  JointAccountSendMainButtonUIOptionsProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemLocalization
import TangemUI

final class JointAccountSendMainButtonUIOptionsProvider: SendMainButtonUIOptionsProvider {
    private let base: any SendMainButtonUIOptionsProvider

    init(base: any SendMainButtonUIOptionsProvider) {
        self.base = base
    }

    func mainButtonTitle(mainButtonType: SendMainButtonType, flowActionType: SendFlowActionType) -> String {
        switch mainButtonType {
        case .action: Localization.jointAccountSendCreateRequest
        case .close: Localization.commonDone
        default: base.mainButtonTitle(mainButtonType: mainButtonType, flowActionType: flowActionType)
        }
    }

    func mainButtonNeedsHoldAction(mainButtonType: SendMainButtonType, flowActionType: SendFlowActionType) -> Bool {
        base.mainButtonNeedsHoldAction(mainButtonType: mainButtonType, flowActionType: flowActionType)
    }

    func mainButtonIcon(mainButtonType: SendMainButtonType, flowActionType: SendFlowActionType) -> MainButton.Icon? {
        base.mainButtonIcon(mainButtonType: mainButtonType, flowActionType: flowActionType)
    }
}
