//
//  PolymarketLiveGameCard.swift
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

public struct PolymarketLiveGameCard: View, Equatable {
    private let model: Model

    public init(model: Model) {
        self.model = model
    }

    public var body: some View {
        VStack(spacing: 0) {
            header

            divider

            versus

            outcomeButtons
        }
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity)
        .background(DesignSystem.Color.bgSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius, style: .continuous))
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(model.title)
                .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)

            PolymarketMarketMetaRow(
                category: model.category,
                volume: model.volumeText.map { .init(title: Constants.volumePrefix, value: $0) }
            )
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }

    private var divider: some View {
        DesignSystem.Color.borderPrimary
            .frame(height: 1)
            .padding(.top, 15)
            .padding(.horizontal, 16)
    }

    // MARK: - Versus

    private var versus: some View {
        VStack(spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                PolymarketAvatarView(url: model.home.logoURL)

                HStack(spacing: 12) {
                    scoreText(model.score?.home, alignment: .leading)

                    status

                    scoreText(model.score?.away, alignment: .trailing)
                }
                .frame(minHeight: PolymarketAvatarView.defaultSide)

                PolymarketAvatarView(url: model.away.logoURL)
            }

            HStack(spacing: 8) {
                teamName(model.home.name, alignment: .leading)

                teamName(model.away.name, alignment: .trailing)
            }
        }
        .padding(16)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(versusAccessibilityLabel)
        .accessibilityValue(statusAccessibilityValue)
    }

    private func scoreText(_ score: String?, alignment: Alignment) -> some View {
        Text(score ?? "")
            .style(DesignSystem.Font.headingMediumToken, color: DesignSystem.Color.textPrimary)
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: alignment)
    }

    private var status: some View {
        VStack(spacing: 4) {
            if model.showsLiveBadge {
                PolymarketLiveBadge(isPulsing: true)
            }

            if let period = model.period {
                Text(period)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func teamName(_ name: String, alignment: Alignment) -> some View {
        Text(name)
            .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
            .lineLimit(1)
            .truncationMode(.tail)
            .frame(maxWidth: .infinity, alignment: alignment)
    }

    // MARK: - Outcomes

    private var outcomeButtons: some View {
        HStack(spacing: 8) {
            ForEach(model.outcomes) { outcome in
                PolymarketOutcomeButton(
                    outcome: outcome,
                    isWide: true,
                    labelStyle: .compact,
                    horizontalPadding: model.outcomes.count > Constants.roomyOutcomeCount
                        ? Constants.compactOutcomePadding
                        : Constants.regularOutcomePadding
                )
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Accessibility

    private var versusAccessibilityLabel: String {
        [model.home, model.away]
            .enumerated()
            .map { index, team in
                let score = index == 0 ? model.score?.home : model.score?.away
                return [team.name, score].compactMap { $0 }.joined(separator: " ")
            }
            .joined(separator: ", ")
    }

    private var statusAccessibilityValue: String {
        [model.showsLiveBadge ? Localization.predictionEventLive : nil, model.period]
            .compactMap { $0 }
            .joined(separator: ", ")
    }
}

// MARK: - Constants

private extension PolymarketLiveGameCard {
    enum Constants {
        static let cornerRadius: CGFloat = 24
        static let volumePrefix = Localization.predictionEventTotalVolume
        static let roomyOutcomeCount = 2
        static let regularOutcomePadding: CGFloat = 14
        static let compactOutcomePadding: CGFloat = 8
    }
}
