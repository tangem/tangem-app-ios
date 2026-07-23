//
//  MarketsTokenDetailsSecurityScoreViewRedesign.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAccessibilityIdentifiers
import TangemAssets
import TangemUI
import TangemUIUtils

struct MarketsTokenDetailsSecurityScoreViewRedesign: View {
    let viewModel: MarketsTokenDetailsSecurityScoreViewModel

    @ScaledMetric private var starSize: CGFloat = 20
    @ScaledMetric private var starsSpacing: CGFloat = 4
    @ScaledMetric private var verticalSpacing: CGFloat = 8

    var body: some View {
        VStack(spacing: verticalSpacing) {
            topRow

            bottomRow
        }
        .roundedBackground(with: DesignSystem.Color.bgSecondary, padding: 16, radius: 24)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(MarketsAccessibilityIdentifiers.securityScoreBlock)
    }

    private var topRow: some View {
        HStack(alignment: .top) {
            scoreValue

            Spacer()

            starsView
        }
    }

    private var bottomRow: some View {
        HStack(alignment: .center) {
            infoButton

            Spacer()

            subtitle
        }
    }
}

// MARK: - Subviews

private extension MarketsTokenDetailsSecurityScoreViewRedesign {
    var scoreValue: some View {
        Text(viewModel.ratingViewData.securityScore)
            .style(DesignSystem.Font.headingSmallToken, color: DesignSystem.Color.textPrimary)
            .lineLimit(1)
            .accessibilityIdentifier(MarketsAccessibilityIdentifiers.securityScoreValue)
    }

    var starsView: some View {
        HStack(spacing: starsSpacing) {
            ForEach(viewModel.ratingViewData.ratingBullets.indexed(), id: \.0) { _, bullet in
                starImage(for: bullet)
                    .resizable()
                    .renderingMode(.template)
                    .foregroundStyle(DesignSystem.Color.iconAccentBlue)
                    .frame(width: starSize, height: starSize)
            }
        }
        .accessibilityIdentifier(MarketsAccessibilityIdentifiers.securityScoreRatingStars)
    }

    var infoButton: some View {
        SwiftUI.Button(action: viewModel.onInfoButtonTap) {
            HStack(spacing: 4) {
                DesignSystem.Icons.Info.regular16.image
                    .renderingMode(.template)
                    .foregroundStyle(DesignSystem.Color.iconSecondary)

                Text(viewModel.title)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                    .lineLimit(1)
            }
        }
        .accessibilityIdentifier(MarketsAccessibilityIdentifiers.securityScoreInfoButton)
    }

    var subtitle: some View {
        Text(viewModel.subtitle)
            .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
            .lineLimit(1)
            .accessibilityIdentifier(MarketsAccessibilityIdentifiers.securityScoreReviewsCount)
    }

    func starImage(for bullet: MarketsTokenDetailsSecurityScoreRatingViewData.RatingBullet) -> Image {
        let asset: ImageType
        switch bullet.value {
        case 0.75...:
            asset = Assets.DesignSystem.starFilled

        case 0.5 ..< 0.75:
            asset = Assets.DesignSystem.starHalfFilled

        case Double.ulpOfOne ..< 0.5:
            asset = Assets.DesignSystem.starAlmostFilled

        default:
            asset = Assets.DesignSystem.starEmpty
        }

        return asset.image
    }
}

// MARK: - Previews

#Preview {
    MarketsTokenDetailsSecurityScoreViewRedesign(
        viewModel: MarketsTokenDetailsSecurityScoreViewModel(
            securityScoreValue: 4.3,
            providers: [
                MarketsTokenDetailsSecurityScore.Provider(
                    id: "provider1",
                    name: "Provider #1",
                    securityScore: 4.5,
                    auditDate: Date(),
                    auditURL: URL(string: "https://www.certik.com")
                ),
                MarketsTokenDetailsSecurityScore.Provider(
                    id: "provider2",
                    name: "Provider #2",
                    securityScore: 4.1,
                    auditDate: nil,
                    auditURL: nil
                ),
            ],
            routable: nil
        )
    )
    .padding()
    .background(DesignSystem.Color.bgPrimary)
}
