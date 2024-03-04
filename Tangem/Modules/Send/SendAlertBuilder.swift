//
//  SendAlertBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

enum SendAlertBuilder {
    static func makeSubtractFeeFromAmountAlert(subtractAction: @escaping () -> Void) -> AlertBinder {
        let subtractButton = Alert.Button.default(Text(Localization.sendAlertFeeCoverageSubractText), action: subtractAction)
        return AlertBuilder.makeAlert(
            title: "",
            message: Localization.sendAlertFeeCoverageTitle,
            primaryButton: subtractButton,
            secondaryButton: .cancel()
        )
    }
}
