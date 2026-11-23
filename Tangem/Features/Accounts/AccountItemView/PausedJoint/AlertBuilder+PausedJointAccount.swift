//
//  AlertBuilder+PausedJointAccount.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import struct TangemUIUtils.AlertBinder

extension AlertBuilder {
    static func makePausedJointAccountAlert(onContactSupport: @escaping () -> Void) -> AlertBinder {
        makeAlert(
            title: Localization.jointAccountCompromisedTitle,
            message: Localization.jointAccountCompromisedMessage,
            primaryButton: .default(Text(Localization.commonContactSupport), action: onContactSupport),
            secondaryButton: .cancel()
        )
    }
}
