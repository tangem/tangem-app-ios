//
//  PolymarketWelcomeContent.swift
//  TangemPolymarketUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemAssets
import TangemLocalization

public enum PolymarketWelcomeContent {
    public static let highlights: [Highlight] = [
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

    public static let questions: [Question] = [
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

public extension PolymarketWelcomeContent {
    struct Highlight: Identifiable {
        public let icon: ImageType
        public let title: String
        public let subtitle: String

        public var id: String { title }
    }

    struct Question: Identifiable {
        public let title: String
        public let answer: String

        public var id: String { title }
    }
}
