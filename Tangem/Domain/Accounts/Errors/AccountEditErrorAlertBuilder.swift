//
//  AccountEditErrorAlertBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemLocalization
import struct TangemUIUtils.AlertBinder

enum AccountEditErrorAlertBuilder {
    static func makeAlert(for error: AccountEditError) -> AlertBinder {
        let title: String
        let message: String
        let buttonText: String

        switch error {
        case .tooManyAccounts:
            title = Localization.accountAddLimitDialogTitle
            message = Localization.accountAddLimitDialogDescription(AccountModelUtils.maxNumberOfAccounts)
            buttonText = Localization.commonGotIt
        case .duplicateAccountName:
            title = Localization.accountFormNameAlreadyExistErrorTitle
            message = Localization.accountFormNameAlreadyExistErrorDescription
            buttonText = Localization.commonGotIt
        case .invalidAccountName, .missingAccountName, .unknownError:
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
