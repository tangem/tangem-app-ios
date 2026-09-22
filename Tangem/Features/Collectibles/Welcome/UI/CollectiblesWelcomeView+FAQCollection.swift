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
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    if index > 0 {
                        Separator(height: .minimal, color: DesignSystem.Color.borderSecondary)
                    }

                    ItemView(item: item)
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

// MARK: - FAQCollection + ItemView

private extension FAQCollection {
    struct ItemView: View {
        let item: Item

        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                Text(item.question)
                    .style(DesignSystem.Font.headingSmallToken, color: DesignSystem.Color.textPrimary)

                Text(item.answer)
                    .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textSecondary)
            }
            .infinityFrame(axis: .horizontal, alignment: .leading)
        }
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
