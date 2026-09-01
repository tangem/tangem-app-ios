//
//  PolymarketWelcomeCopy.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

struct PolymarketWelcomeCopy {
    let title: String
    let subtitle: String
    let actionTitle: String

    // [REDACTED_TODO_COMMENT]
    init(hasExistingAccount: Bool) {
        guard hasExistingAccount else {
            title = Localization.predictionOnboardingTitle
            subtitle = Localization.predictionOnboardingSubtitle
            actionTitle = Localization.predictionOnboardingStartButton

            return
        }

        title = "Continue predicting"
        subtitle = "Your prediction account is ready, authorize this device to keep trading"
        actionTitle = "Continue"
    }
}
