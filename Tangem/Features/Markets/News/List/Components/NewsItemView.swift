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
            ? DesignSystem.Color.textSecondary
            : DesignSystem.Color.textPrimary
    }

    private var rating: String {
        "\(viewModel.score) \(AppConstants.dotSign) \(viewModel.relativeTime)"
    }

    var body: some View {
        SwiftUI.Button(action: onTap) {
            redesignContent
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
            NewsRatingViewRedesign(rating: rating, isHighlighted: false, font: DesignSystem.Font.captionMediumToken)

            FixedSpacer(height: 8)

            Text(viewModel.title)
                .style(DesignSystem.Font.bodyMediumToken, color: textColor)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .topLeading)

            FixedSpacer(height: 32)

            InfoChipsRowView(chips: viewModel.chips, alignment: .leading, style: .redesign)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(DesignSystem.Color.bgSecondary)
        .cornerRadiusContinuous(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .inset(by: 0.5)
                .stroke(DesignSystem.Color.borderSecondary, lineWidth: 1)
        )
        .opacity(viewModel.isRead ? 0.6 : 1.0)
    }

    private var redesignTrendingContent: some View {
        VStack(alignment: .leading, spacing: .zero) {
            HStack(spacing: 8) {
                NewsRatingViewRedesign(rating: rating, isHighlighted: true, font: DesignSystem.Font.captionMediumToken)
                Text(Localization.feedTrendingNow)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textPrimary)
            }

            FixedSpacer(height: 8)

            Text(viewModel.title)
                .style(DesignSystem.Font.headingSmallToken, color: DesignSystem.Color.textPrimary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .topLeading)

            FixedSpacer(height: 32)

            InfoChipsRowView(chips: viewModel.chips, alignment: .leading, style: .redesign)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        // [DS3] Trending background flattened from the decorative `trendingNewsBackground` image to a flat
        // surface, matching the sibling Shtorka widget cards (Surface.level3 → bgSecondary). Flag for design.
        .background(DesignSystem.Color.bgSecondary)
        .cornerRadiusContinuous(20)
        .opacity(viewModel.isRead ? 0.6 : 1.0)
    }
}
