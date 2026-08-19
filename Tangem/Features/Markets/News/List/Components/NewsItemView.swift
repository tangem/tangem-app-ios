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
        .background(content: TrendingNewsGlowBackground.init)
        .cornerRadiusContinuous(20)
        .opacity(viewModel.isRead ? 0.6 : 1.0)
    }
}

// MARK: - TrendingNewsGlowBackground

private struct TrendingNewsGlowBackground: View {
    var body: some View {
        Ellipse()
            .fill(Color(hex: Constants.hex).opacity(Constants.opacity))
            .frame(height: Constants.height)
            .padding(.horizontal, -Constants.horizontalOverflow)
            .blur(radius: Constants.blur)
            .offset(y: Constants.height / 2 + Constants.bottomInset)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .background(DesignSystem.Color.bgSecondary)
    }
}

private extension TrendingNewsGlowBackground {
    enum Constants {
        static let hex = "7C16F1"
        static let opacity: Double = 0.27
        static let height: CGFloat = 170
        static let horizontalOverflow: CGFloat = 75
        static let blur: CGFloat = 66
        static let bottomInset: CGFloat = 48
    }
}
