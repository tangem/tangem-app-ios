//
//  NativePaymentError.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import struct TangemUIUtils.AlertBinder

enum NativePaymentError: LocalizedError, BindableError {
    case timeout

    var binder: AlertBinder {
        AlertBinder(
            title: Localization.commonSomethingWentWrong,
            message: Localization.accountGenericErrorDialogMessage
        )
    }
}
