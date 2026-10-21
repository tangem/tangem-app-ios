//
//  PolymarketEventCard.swift
//  TangemPolymarketUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemFoundation
import TangemLocalization
import TangemUI
import TangemUIUtils

public struct PolymarketEventCard: View, Equatable {
    private let model: Model

    public init(model: Model) {
        self.model = model
    }

    public var body: some View {
        content
            .frame(maxWidth: .infinity)
            .background(DesignSystem.Color.bgSecondary)
            .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius, style: .continuous))
    }

    // MARK: - Content

    private var content: some View {
        VStack(spacing: 0) {
            header

            marketBody

            bottomSection
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text(model.title)
                    .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)

                metaRow
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            PolymarketAvatarView(url: model.imageURL)
        }
        .padding(16)
    }

    private var metaRow: some View {
        PolymarketMarketMetaRow(
            isLive: model.isLive,
            category: model.category,
            volume: model.volumeText.map { .init(title: Constants.volumePrefix, value: $0) }
        )
    }

    // MARK: - Market body

    @ViewBuilder
    private var marketBody: some View {
        VStack(spacing: 0) {
            ForEach(Array(model.rows.enumerated()), id: \.element.id) { index, row in
                marketRow(row)

                if model.variant == .multiMarket, index < model.rows.count - 1 {
                    rowDivider
                }
            }
        }
    }

    @ViewBuilder
    private func marketRow(_ row: Row) -> some View {
        if let title = row.title {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textPrimary)
                        .lineLimit(1)
                        .truncationMode(.tail)

                    if let subtitle = row.subtitle {
                        Text(subtitle)
                            .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .combine)

                outcomeButtons(row, areWide: false)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        } else {
            outcomeButtons(row, areWide: true)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
        }
    }

    private func outcomeButtons(_ row: Row, areWide: Bool) -> some View {
        HStack(spacing: 4) {
            ForEach(row.outcomes) { outcome in
                outcomeButton(outcome, isWide: areWide)
            }
        }
    }

    private func outcomeButton(_ outcome: Outcome, isWide: Bool) -> some View {
        Button(action: outcome.onSelect) {
            HStack(spacing: Constants.outcomeSpacing) {
                Text(outcome.title)
                    .lineLimit(1)
                    .truncationMode(.tail)

                if let priceText = outcome.priceText {
                    Text(Constants.priceSeparator + priceText)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                        .layoutPriority(1)
                        .contentTransition(.numericText())
                        .animation(Constants.priceChangeAnimation, value: priceText)
                }
            }
            .style(DesignSystem.Font.bodyMediumToken, color: outcome.style.foregroundColor)
            .padding(.horizontal, 14)
            .frame(minWidth: isWide ? 0 : 56, maxWidth: isWide ? .infinity : nil, minHeight: 36)
            .background(outcome.style.backgroundColor, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(outcome.priceText.map { "\(outcome.title) \($0)" } ?? outcome.title)
    }

    private var rowDivider: some View {
        DesignSystem.Color.borderPrimary
            .frame(height: 1)
            .padding(.horizontal, 16)
    }

    // MARK: - Bottom

    @ViewBuilder
    private var bottomSection: some View {
        if hasBottomAccessory {
            HStack(spacing: 8) {
                if showsOutcomesBadge {
                    Badge(label: Constants.outcomesLabel(model.additionalOutcomesCount), accessibilityLabel: nil)
                        .size(.x6)
                        .variant(.outline)
                        .appearance(.neutral)
                }

                Spacer(minLength: 0)

                if model.isInActivePredicts {
                    Badge(label: Constants.activePredictsLabel, accessibilityLabel: nil)
                        .size(.x6)
                        .variant(.outline)
                        .appearance(.info)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 16)
        } else {
            Color.clear.frame(height: 4)
        }
    }

    private var showsOutcomesBadge: Bool {
        model.variant == .multiMarket && model.additionalOutcomesCount > 0
    }

    private var hasBottomAccessory: Bool {
        showsOutcomesBadge || model.isInActivePredicts
    }
}

// MARK: - Constants

private extension PolymarketEventCard {
    enum Constants {
        static let cornerRadius: CGFloat = 24
        static let outcomeSpacing: CGFloat = 4
        static let priceSeparator = String.bulletSign + " "
        static let priceChangeAnimation = Animation.curve(.easeInOutRefined, duration: 0.3)

        static let volumePrefix = Localization.predictionEventTotalVolume

        // [REDACTED_TODO_COMMENT]
        static let activePredictsLabel = "In your active predicts"

        // [REDACTED_TODO_COMMENT]
        static func outcomesLabel(_ count: Int) -> String {
            "+\(count) Outcomes"
        }
    }
}
