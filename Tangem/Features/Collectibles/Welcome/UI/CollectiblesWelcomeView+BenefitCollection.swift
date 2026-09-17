//
//  CollectiblesWelcomeView+BenefitCollection.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUIUtils

private typealias BenefitCollection = CollectiblesWelcomeView.BenefitCollection

extension CollectiblesWelcomeView {
    struct BenefitCollection: View {
        private let columns = [
            GridItem(.flexible(), spacing: Metrics.spacing),
            GridItem(.flexible(), spacing: Metrics.spacing),
        ]

        private let items = Item.content

        var body: some View {
            LazyVGrid(columns: columns, alignment: .leading, spacing: Metrics.spacing) {
                ForEach(items, id: \.title, content: Card.init)
            }
        }
    }
}

// MARK: - BenefitCollection + Item

private extension BenefitCollection {
    struct Item {
        let icon: ImageType
        let title: String
        let subtitle: String

        static let content: [Self] = [
            .init(
                icon: DesignSystem.Icons.Lightning.regular24,
                title: Localization.collectiblesWelcomeBenefitTaplessTitle,
                subtitle: Localization.collectiblesWelcomeBenefitTaplessSubtitle
            ),
            .init(
                icon: DesignSystem.Icons.ShieldCheckmark.regular24,
                title: Localization.collectiblesWelcomeBenefitColdWalletTitle,
                subtitle: Localization.collectiblesWelcomeBenefitColdWalletSubtitle
            ),
            .init(
                icon: DesignSystem.Icons.ShieldCheckmark.regular24,
                title: Localization.collectiblesWelcomeBenefitTransparencyTitle,
                subtitle: Localization.collectiblesWelcomeBenefitTransparencySubtitle
            ),
            .init(
                icon: DesignSystem.Icons.Wallet.regular24,
                title: Localization.collectiblesWelcomeBenefitSellOffersTitle,
                subtitle: Localization.collectiblesWelcomeBenefitSellOffersSubtitle
            ),
        ]
    }
}

// MARK: - BenefitCollection + Card

private extension BenefitCollection {
    struct Card: View {
        let item: BenefitCollection.Item

        @ScaledMetric private var iconSize: CGFloat = 24
        @ScaledMetric private var minHeight: CGFloat = 136

        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                item.icon.image
                    .renderingMode(.template)
                    .resizable()
                    .frame(size: CGSize(bothDimensions: iconSize))
                    .foregroundStyle(DesignSystem.Color.iconPrimary)

                Spacer(minLength: 0)

                VStack(alignment: .leading, spacing: DesignSystem.Font.captionMediumToken.lineSpacing) {
                    Text(item.title)
                        .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textPrimary)

                    Text(item.subtitle)
                        .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                }
            }
            .padding(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 24))
            .frame(maxWidth: .infinity, minHeight: minHeight, alignment: .leading)
            .background(DesignSystem.Color.bgSecondary)
            .cornerRadiusContinuous(Metrics.cornerRadius)
        }
    }
}

// MARK: - Metrics

private extension BenefitCollection {
    enum Metrics {
        static let spacing: CGFloat = 8
        static let cornerRadius: CGFloat = 24
    }
}

// MARK: - Previews

#Preview {
    ZStack {
        DesignSystem.Color.bgPrimary.ignoresSafeArea()

        CollectiblesWelcomeView.BenefitCollection()
            .padding(24)
    }
}
