//
//  GachaWelcomeView+FAQCollection.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

private typealias FAQCollection = GachaWelcomeView.FAQCollection

extension GachaWelcomeView {
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

        // [REDACTED_TODO_COMMENT]
        static let content: [Self] = [
            .init(
                question: "What happens when I tap my card?",
                answer: "A sealed pack containing one graded physical collectible card, held 1:1 in an insured physical vault and redeemable for delivery at any time. Every card inside a machine is transparently visible in the app and the draw odds are published up front"
            ),
            .init(
                question: "What are the risks?",
                answer: "Collectible values change and can fall. Some cards in a pack pool can be worth less than the pack price — never nothing, but less than you paid. Only spend what you're comfortable spending on collectibles. This is not financial advice"
            ),
            .init(
                question: "Who provides the service?",
                answer: "Collector Crypt provides the card inventory, the packs, the physical vault, the instant offers and the shipping, under its own terms. Tangem provides a passive interface for accessing that service and for signing — it never holds your cards, your funds or your keys"
            ),
            .init(
                question: "Is it available where I live?",
                answer: "Availability varies by region and some countries are restricted. Age limits may apply. You're responsible for following the laws and regulations of your own jurisdiction"
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
