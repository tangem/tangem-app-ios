//
//  JointAccountOperationSigningErrorAlert.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemLocalization
import struct TangemUIUtils.AlertBinder

struct JointAccountOperationSigningErrorAlert: Equatable {
    let title: String
    let message: String
    let buttonText: String

    init(error: Error) {
        switch error as? JointOperationError {
        case .maliciousOperation:
            title = Localization.jointOperationMaliciousTitle
            message = Localization.jointOperationMaliciousSubtitle
            buttonText = Localization.commonClose
        case .unsupportedOperationForm:
            title = Localization.jointOperationSigningBlockedTitle
            message = Localization.jointOperationSigningBlockedSubtitle
            buttonText = Localization.commonClose
        default:
            title = Localization.commonSomethingWentWrong
            message = Localization.accountGenericErrorDialogMessage
            buttonText = Localization.commonOk
        }
    }

    var alertBinder: AlertBinder {
        AlertBuilder.makeAlertWithDefaultPrimaryButton(title: title, message: message, buttonText: buttonText)
    }
}
