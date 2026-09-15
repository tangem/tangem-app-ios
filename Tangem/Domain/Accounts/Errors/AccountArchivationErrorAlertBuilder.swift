//
//  AccountArchivationErrorAlertBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemLocalization
import struct TangemUIUtils.AlertBinder

enum AccountArchivationErrorAlertBuilder {
    static func makeAlert(for error: AccountArchivationError) -> AlertBinder {
        let title: String
        let message: String
        let buttonText: String

        switch error {
        case .participatesInReferralProgram:
            title = Localization.accountCouldNotArchiveReferralProgramTitle
            message = Localization.accountCouldNotArchiveReferralProgramMessage
            buttonText = Localization.commonGotIt
        case .unknownError:
            title = Localization.commonSomethingWentWrong
            message = Localization.accountGenericErrorDialogMessage
            buttonText = Localization.commonOk
        }

        return AlertBuilder.makeAlertWithDefaultPrimaryButton(
            title: title,
            message: message,
            buttonText: buttonText
        )
    }
}
