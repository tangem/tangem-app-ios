//
//  CommonSendMainButtonUIOptionsProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemUI

final class CommonSendMainButtonUIOptionsProvider: SendMainButtonUIOptionsProvider {
    private weak var sourceTokenInput: SendSourceTokenInput?

    init(sourceTokenInput: any SendSourceTokenInput) {
        self.sourceTokenInput = sourceTokenInput
    }

    func mainButtonNeedsHoldAction(mainButtonType: SendMainButtonType, flowActionType: SendFlowActionType) -> Bool {
        switch mainButtonType {
        case .action where flowActionType == .approve: false
        case .action: sourceTokenInput?.sourceToken.value?.confirmTransactionPolicy.needsHoldToConfirm ?? false
        default: false
        }
    }

    func mainButtonIcon(mainButtonType: SendMainButtonType, flowActionType: SendFlowActionType) -> MainButton.Icon? {
        switch mainButtonType {
        case .action: sourceTokenInput?.sourceToken.value?.tangemIconProvider.getMainButtonIcon()
        default: nil
        }
    }
}
