//
//  MobileSocialWalletFailure.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import struct TangemUIUtils.AlertBinder

enum MobileSocialWalletFailure {
    case somethingWentWrong

    var title: String {
        switch self {
        case .somethingWentWrong:
            Localization.commonSomethingWentWrong
        }
    }

    var message: String {
        switch self {
        case .somethingWentWrong:
            Localization.socialLoginErrorGenericV2
        }
    }

    func makeAlert(dismissAction: @escaping () -> Void = {}) -> AlertBinder {
        AlertBuilder.makeAlertWithDefaultPrimaryButton(
            title: title,
            message: message,
            buttonText: Localization.commonGotIt,
            buttonAction: dismissAction
        )
    }
}
