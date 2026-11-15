//
//  SendMainButtonUIOptionsProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemUI

protocol SendMainButtonUIOptionsProvider {
    func mainButtonSigningActionButtonType(mainButtonType: SendMainButtonType, flowActionType: SendFlowActionType) -> SigningActionButtonViewType?
}
