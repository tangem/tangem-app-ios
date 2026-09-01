//
//  PolymarketWelcomeContent.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemAssets
import TangemLocalization
import TangemUI

enum PolymarketWelcomeContent {
    static let highlights: [Highlight] = [
        Highlight(
            icon: DesignSystem.Icons.Lightning.regular24,
            title: Localization.predictionOnboardingBenefitFundTitle,
            subtitle: Localization.predictionOnboardingBenefitFundSubtitle
        ),
        Highlight(
            icon: DesignSystem.Icons.ShieldCheckmark.filled24,
            title: Localization.predictionOnboardingBenefitCustodyTitle,
            subtitle: Localization.predictionOnboardingBenefitCustodySubtitle
        ),
        Highlight(
            icon: DesignSystem.Icons.PercentBackward.regular24,
            title: Localization.predictionOnboardingBenefitHistoryTitle,
            subtitle: Localization.predictionOnboardingBenefitHistorySubtitle
        ),
        Highlight(
            icon: DesignSystem.Icons.Wallet.regular24,
            title: Localization.predictionOnboardingBenefitPayoutTitle,
            subtitle: Localization.predictionOnboardingBenefitPayoutSubtitle
        ),
    ]

    static let questions: [Question] = [
        Question(
            title: Localization.predictionOnboardingFaqTapQuestion,
            answer: Localization.predictionOnboardingFaqTapAnswer
        ),
        Question(
            title: Localization.predictionOnboardingFaqRisksQuestion,
            answer: Localization.predictionOnboardingFaqRisksAnswer
        ),
        Question(
            title: Localization.predictionOnboardingFaqAvailabilityQuestion,
            answer: Localization.predictionOnboardingFaqAvailabilityAnswer
        ),
    ]
}

// MARK: - Auxiliary types

extension PolymarketWelcomeContent {
    struct Highlight: Identifiable {
        let icon: ImageType
        let title: String
        let subtitle: String

        var id: String { title }
    }

    struct Question: Identifiable {
        let title: String
        let answer: String

        var id: String { title }
    }
}
