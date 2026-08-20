//
//  PolymarketEventCard.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import Kingfisher
import TangemAssets
import TangemUI
import TangemUIUtils

struct PolymarketEventCard: View {
    private let model: Model

    init(model: Model) {
        self.model = model
    }

    var body: some View {
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

            circleImage(url: model.imageURL)
        }
        .padding(16)
    }

    @ViewBuilder
    private var metaRow: some View {
        if model.category != nil || model.volumeText != nil {
            HStack(spacing: 8) {
                if let category = model.category {
                    categoryBadge(category)
                }

                if let volumeText = model.volumeText {
                    volumeView(volumeText)
                }
            }
        }
    }

    private func categoryBadge(_ category: Category) -> some View {
        HStack(spacing: 0) {
            if let iconURL = category.iconURL {
                KFImage(iconURL)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .accessibilityHidden(true)
            }

            Text(category.name)
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                .lineLimit(1)
                .padding(.horizontal, 2)
        }
        .padding(.horizontal, 2)
        .frame(minHeight: 16)
        .background(DesignSystem.Color.bgOpaquePrimary, in: Capsule())
    }

    private func volumeView(_ volumeText: String) -> some View {
        HStack(spacing: 4) {
            Text(Constants.volumePrefix)
                .foregroundStyle(DesignSystem.Color.textSecondary)

            Text(volumeText)
                .foregroundStyle(DesignSystem.Color.textPrimary)
        }
        .font(token: DesignSystem.Font.captionMediumToken)
        .lineLimit(1)
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

    private func marketRow(_ row: Row) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(row.title)
                    .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textPrimary)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Text(row.subtitle)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)

            outcomeButtons(row)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func outcomeButtons(_ row: Row) -> some View {
        HStack(spacing: 4) {
            ForEach(row.outcomes) { outcome in
                outcomeButton(outcome)
            }
        }
    }

    private func outcomeButton(_ outcome: Outcome) -> some View {
        Button(action: outcome.onSelect) {
            Text(outcome.title)
                .style(DesignSystem.Font.bodyMediumToken, color: outcome.style.foregroundColor)
                .lineLimit(1)
                .padding(.horizontal, 14)
                .frame(minWidth: 56, minHeight: 36)
                .background(outcome.style.backgroundColor, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(outcome.title)
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

    // MARK: - Shared

    @ViewBuilder
    private func circleImage(url: URL?) -> some View {
        Group {
            if let url {
                KFImage(url)
                    .cancelOnDisappear(true)
                    .placeholder { Shimmer().clipShape(.circle) }
                    .resizable()
                    .scaledToFill()
            } else {
                DesignSystem.Color.bgOpaquePrimary
            }
        }
        .frame(width: 40, height: 40)
        .clipShape(Circle())
        .overlay { Circle().stroke(DesignSystem.Color.borderPrimary, lineWidth: 1) }
        .accessibilityHidden(true)
    }
}

// MARK: - Constants

private extension PolymarketEventCard {
    enum Constants {
        static let cornerRadius: CGFloat = 24

        // [REDACTED_TODO_COMMENT]
        static let volumePrefix = "Total volume:"
        static let activePredictsLabel = "In your active predicts"

        static func outcomesLabel(_ count: Int) -> String {
            "+\(count) Outcomes"
        }
    }
}

// MARK: - Outcome style colors

private extension PolymarketEventCard.Outcome.Style {
    var backgroundColor: Color {
        switch self {
        case .affirmative: DesignSystem.Color.bgStatusInfoSubtle
        case .negative: DesignSystem.Color.bgStatusErrorSubtle
        }
    }

    var foregroundColor: Color {
        switch self {
        case .affirmative: DesignSystem.Color.textBrand
        case .negative: DesignSystem.Color.textStatusError
        }
    }
}
