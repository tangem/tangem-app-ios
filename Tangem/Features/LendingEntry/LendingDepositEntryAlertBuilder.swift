//
//  LendingDepositEntryAlertBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import struct TangemUIUtils.AlertBinder

enum LendingDepositEntryAlertBuilder {
    static func readFailedAlert(retry: @escaping () -> Void) -> AlertBinder {
        AlertBuilder.makeAlert(
            title: Localization.commonSomethingWentWrong,
            message: Localization.commonTryAgainLater,
            primaryButton: .default(Text(Localization.alertButtonTryAgain), action: retry),
            secondaryButton: .cancel(Text(Localization.commonClose))
        )
    }

    // [REDACTED_TODO_COMMENT]
    static func updateRequiredAlert() -> AlertBinder {
        AlertBuilder.makeAlert(
            title: Localization.forceUpdateWarningTitle,
            message: "Update Tangem to the latest version to use Lending on Aave.",
            primaryButton: .default(Text(Localization.forceUpdateRequiredAction), action: AppStoreOpener.open),
            secondaryButton: .cancel(Text(Localization.commonClose))
        )
    }
}
