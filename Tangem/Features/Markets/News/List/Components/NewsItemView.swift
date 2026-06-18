//
//  NewsItemView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils
import TangemUI
import TangemLocalization
import TangemFoundation

struct NewsItemView: View {
    let viewModel: NewsItemViewModel
    let onTap: () -> Void

    private var textColor: Color {
        viewModel.isRead
            ? Color.Tangem.Text.Neutral.tertiary
            : Color.Tangem.Text.Neutral.primary
    }

    var body: some View {
        Button(action: onTap) {
            if FeatureProvider.isAvailable(.redesign) {
                redesignContent
            } else {
                legacyContent
            }
        }
        .buttonStyle(.scaled())
    }

    // MARK: - Redesign

    @ViewBuilder
    private var redesignContent: some View {
        if viewModel.isTrending {
            redesignTrendingContent
        } else {
            redesignRegularContent
        }
    }

    private var redesignRegularContent: some View {
        VStack(alignment: .leading, spacing: .zero) {
            NewsRatingViewRedesign(rating: viewModel.score, isHighlighted: false)

            FixedSpacer(height: .unit(.x2))

            Text(viewModel.title)
                .style(Font.Tangem.Body16.regular, color: textColor)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .topLeading)

            FixedSpacer(height: .unit(.x2))

            Text(viewModel.relativeTime)
                .style(Font.Tangem.Caption12.semibold, color: .Tangem.Text.Neutral.secondary)

            FixedSpacer(height: .unit(.x2))

            InfoChipsRowView(chips: viewModel.chips, alignment: .leading, style: .redesign)
        }
        .padding(.unit(.x4))
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(Color.Tangem.Surface.level3)
        .cornerRadiusContinuous(.unit(.x5))
        .overlay(
            RoundedRectangle(cornerRadius: .unit(.x5), style: .continuous)
                .inset(by: 0.5)
                .stroke(Color.Tangem.Border.Neutral.primary, lineWidth: 1)
        )
        .opacity(viewModel.isRead ? 0.6 : 1.0)
    }

    private var redesignTrendingContent: some View {
        VStack(alignment: .leading, spacing: .zero) {
            HStack(spacing: .unit(.x2)) {
                NewsRatingViewRedesign(rating: viewModel.score, isHighlighted: true)
                Text(Localization.feedTrendingNow)
                    .style(Font.Tangem.Caption12.semibold, color: .Tangem.Text.Neutral.primary)
            }

            FixedSpacer(height: .unit(.x2))

            Text(viewModel.title)
                .style(Font.Tangem.Heading20.semibold, color: .Tangem.Text.Neutral.primary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .topLeading)

            FixedSpacer(height: .unit(.x2))

            Text(viewModel.relativeTime)
                .style(Font.Tangem.Caption12.semibold, color: .Tangem.Text.Neutral.secondary)

            FixedSpacer(height: 18.0)

            InfoChipsRowView(chips: viewModel.chips, alignment: .leading, style: .redesign)
        }
        .padding(.unit(.x4))
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background {
            Assets.Markets
                .trendingNewsBackground
                .image
                .resizable()
                .allowsHitTesting(false)
        }
        .cornerRadiusContinuous(.unit(.x5))
        .opacity(viewModel.isRead ? 0.6 : 1.0)
    }

    // MARK: - Legacy

    private var legacyContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                scoreBadge

                Text(AppConstants.dotSign)
                    .style(Fonts.Bold.footnote, color: Color.Tangem.Text.Neutral.tertiary)

                Text(viewModel.relativeTime)
                    .style(Fonts.Regular.footnote, color: Color.Tangem.Text.Neutral.tertiary)
            }

            Text(viewModel.title)
                .style(Fonts.Bold.title3, color: textColor)
                .lineLimit(nil)
                .multilineTextAlignment(.leading)
                .padding(.bottom, 12)

            InfoChipsRowView(chips: viewModel.chips)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 16)
        .padding(.horizontal, 14)
        .background(Color.Tangem.Surface.level3)
        .cornerRadius(14)
    }

    private var scoreBadge: some View {
        NewsScoreBadgeView(score: viewModel.score, textColor: textColor)
    }
}
