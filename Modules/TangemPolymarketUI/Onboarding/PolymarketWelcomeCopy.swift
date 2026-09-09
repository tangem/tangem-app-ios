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
    public let highlights: [PolymarketWelcomeContent.Highlight]
    public let questions: [PolymarketWelcomeContent.Question]
    public let legalNotice: PolymarketLegalNotice

    public init(hasExistingAccount: Bool) {
        guard hasExistingAccount else {
            title = Localization.predictionOnboardingTitle
            subtitle = Localization.predictionOnboardingSubtitle
            actionTitle = Localization.predictionOnboardingStartButton
            highlights = PolymarketWelcomeContent.highlights
            questions = PolymarketWelcomeContent.questions
            legalNotice = .termsAgreement

            return
        }

        title = Localization.predictionOnboardingReconnectTitle
        subtitle = Localization.predictionOnboardingReconnectSubtitle
        actionTitle = Localization.predictionOnboardingReconnectButton
        highlights = PolymarketWelcomeContent.reconnectHighlights
        questions = PolymarketWelcomeContent.reconnectQuestions
        legalNotice = .termsAlreadyAccepted
    }
}
