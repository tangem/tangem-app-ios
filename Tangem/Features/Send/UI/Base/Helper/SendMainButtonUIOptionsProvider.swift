//
//  SendMainButtonUIOptionsProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemUI

protocol SendMainButtonUIOptionsProvider {
    func mainButtonTitle(mainButtonType: SendMainButtonType, flowActionType: SendFlowActionType) -> String
    func mainButtonNeedsHoldAction(mainButtonType: SendMainButtonType, flowActionType: SendFlowActionType) -> Bool
    func mainButtonIcon(mainButtonType: SendMainButtonType, flowActionType: SendFlowActionType) -> MainButton.Icon?
}

extension SendMainButtonUIOptionsProvider {
    func mainButtonTitle(mainButtonType: SendMainButtonType, flowActionType: SendFlowActionType) -> String {
        mainButtonType.title(action: flowActionType)
    }
}
