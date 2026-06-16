//
//  OnrampSendMainButtonUIOptionsProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemUI

final class OnrampSendMainButtonUIOptionsProvider: SendMainButtonUIOptionsProvider {
    func mainButtonNeedsHoldAction(mainButtonType: SendMainButtonType, flowActionType: SendFlowActionType) -> Bool {
        false
    }

    func mainButtonIcon(mainButtonType: SendMainButtonType, flowActionType: SendFlowActionType) -> MainButton.Icon? {
        nil
    }
}
