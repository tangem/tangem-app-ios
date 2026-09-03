//
//  PolymarketWelcomeCopy.swift
//  TangemPolymarketUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

public struct PolymarketWelcomeCopy {
    public let title: String
    public let subtitle: String
    public let actionTitle: String

    // [REDACTED_TODO_COMMENT]
    public init(hasExistingAccount: Bool) {
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
