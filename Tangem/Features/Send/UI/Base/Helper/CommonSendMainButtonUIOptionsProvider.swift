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

    func mainButtonSigningActionButtonType(mainButtonType: SendMainButtonType, flowActionType: SendFlowActionType) -> SigningActionButtonViewType? {
        switch mainButtonType {
        case .action where flowActionType == .approve: nil
        case .action: sourceTokenInput?.sourceToken.value?.signingActionButtonType
        default: nil
        }
    }
}
