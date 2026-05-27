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

struct MarketsTokenDetailsSecurityScoreViewRedesign: View {
    let viewModel: MarketsTokenDetailsSecurityScoreViewModel

    @ScaledMetric private var starSize: CGFloat = 20
    @ScaledMetric private var starsSpacing: CGFloat = .unit(.x1)
    @ScaledMetric private var verticalSpacing: CGFloat = .unit(.x2)

    var body: some View {
        VStack(spacing: verticalSpacing) {
            topRow

            bottomRow
        }
        .padding(.vertical, .unit(.x5))
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
            .style(.Tangem.Heading28.bold, color: .Tangem.Text.Neutral.primary)
            .lineLimit(1)
            .accessibilityIdentifier(MarketsAccessibilityIdentifiers.securityScoreValue)
    }

    var starsView: some View {
        HStack(spacing: starsSpacing) {
            ForEach(viewModel.ratingViewData.ratingBullets.indexed(), id: \.0) { _, bullet in
                starImage(for: bullet)
                    .resizable()
                    .renderingMode(.template)
                    .foregroundStyle(Color.Tangem.Graphic.Status.accent)
                    .frame(width: starSize, height: starSize)
            }
        }
        .accessibilityIdentifier(MarketsAccessibilityIdentifiers.securityScoreRatingStars)
    }

    var infoButton: some View {
        Button(action: viewModel.onInfoButtonTap) {
            HStack(spacing: .unit(.x1)) {
                Text(viewModel.title)
                    .style(.Tangem.Caption12.semibold, color: .Tangem.Text.Neutral.secondary)
                    .lineLimit(1)

                Assets.infoCircle16.image
                    .renderingMode(.template)
                    .foregroundStyle(Color.Tangem.Graphic.Neutral.tertiaryConstant)
            }
        }
        .accessibilityIdentifier(MarketsAccessibilityIdentifiers.securityScoreInfoButton)
    }

    var subtitle: some View {
        Text(viewModel.subtitle)
            .style(.Tangem.Caption12.semibold, color: .Tangem.Text.Neutral.secondary)
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

#if DEBUG
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
    .background(Color.Tangem.Surface.level1)
}
#endif // DEBUG
