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

    func mainButtonSigningActionButtonType(mainButtonType: SendMainButtonType, flowActionType: SendFlowActionType) -> SigningActionButtonViewType? {
        base.mainButtonSigningActionButtonType(mainButtonType: mainButtonType, flowActionType: flowActionType)
    }
}
