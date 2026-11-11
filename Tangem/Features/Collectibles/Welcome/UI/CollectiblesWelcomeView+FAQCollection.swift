//
//  CollectiblesWelcomeView+FAQCollection.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils

private typealias FAQCollection = CollectiblesWelcomeView.FAQCollection

extension CollectiblesWelcomeView {
    struct FAQCollection: View {
        private let items = Item.content

        var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(indexed: items, id: \.0) { index, item in
                    if index > 0 {
                        Separator(height: .minimal, color: DesignSystem.Color.borderSecondary)
                    }

                    OnboardingTextSection(title: item.question, text: item.answer)
                        .padding(.vertical, Metrics.itemVerticalPadding)
                }
            }
        }
    }
}

// MARK: - FAQCollection + Item

private extension FAQCollection {
    struct Item {
        let question, answer: String

        static let content: [Self] = [
            .init(
                question: Localization.collectiblesWelcomeFaqTapQuestion,
                answer: Localization.collectiblesWelcomeFaqTapAnswer
            ),
            .init(
                question: Localization.collectiblesWelcomeFaqBuyingQuestion,
                answer: Localization.collectiblesWelcomeFaqBuyingAnswer
            ),
            .init(
                question: Localization.collectiblesWelcomeFaqRisksQuestion,
                answer: Localization.collectiblesWelcomeFaqRisksAnswer
            ),
            .init(
                question: Localization.collectiblesWelcomeFaqProviderQuestion,
                answer: Localization.collectiblesWelcomeFaqProviderAnswer
            ),
            .init(
                question: Localization.collectiblesWelcomeFaqAvailabilityQuestion,
                answer: Localization.collectiblesWelcomeFaqAvailabilityAnswer
            ),
        ]
    }
}

// MARK: - Metrics

private extension FAQCollection {
    enum Metrics {
        static let itemVerticalPadding: CGFloat = 24
    }
}

// MARK: - Previews

#Preview {
    ZStack {
        DesignSystem.Color.bgPrimary.ignoresSafeArea()

        FAQCollection()
            .padding(24)
    }
}
