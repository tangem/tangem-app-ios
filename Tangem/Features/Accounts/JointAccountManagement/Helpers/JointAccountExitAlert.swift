//
//  JointAccountExitAlert.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemLocalization
import struct TangemUIUtils.AlertBinder

/// Every step of the joint account creation asks the same thing before letting the gathered input go.
enum JointAccountExitAlert {
    static func make(discardAction: @escaping () -> Void) -> AlertBinder {
        AlertBuilder.makeExitAlert(
            title: Localization.accountUnsavedDialogTitle,
            message: Localization.accountUnsavedDialogMessageCreate,
            keepEditingButtonText: Localization.accountUnsavedDialogActionFirst,
            discardButtonText: Localization.accountUnsavedDialogActionSecond,
            discardAction: discardAction
        )
    }
}
