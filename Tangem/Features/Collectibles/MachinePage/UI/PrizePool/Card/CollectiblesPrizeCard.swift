//
//  CollectiblesPrizeCard.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Kingfisher
import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct CollectiblesPrizeCard: View {
    let model: Model

    var body: some View {
        VStack(alignment: .leading, spacing: Metrics.contentSpacing) {
            artwork
            details
        }
    }
}

private extension CollectiblesPrizeCard {
    // MARK: - View properties

    var artwork: some View {
        Color.clear
            .aspectRatio(Metrics.artworkAspectRatio, contentMode: .fit)
            .overlay { image }
            .overlay(alignment: .topLeading) { gradeBadge }
            .background(DesignSystem.Color.bgSecondary)
            .clipShape(RoundedRectangle(cornerRadius: Metrics.cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: Metrics.cornerRadius, style: .continuous)
                    .strokeBorder(DesignSystem.Color.borderPrimary, lineWidth: 1)
            }
    }

    var image: some View {
        KFImage(model.imageURL)
            .resizable()
            .cancelOnDisappear(true)
            .fade(duration: Constants.fadeDuration)
            .cacheOriginalImage()
            .placeholder { Shimmer() }
            .onFailureView { missingImageBadge }
            .aspectRatio(contentMode: .fill)
    }

    @ViewBuilder
    var gradeBadge: some View {
        if let gradeText = model.gradeText {
            Badge(label: gradeText, accessibilityLabel: nil)
                .size(.x4)
                .padding(Metrics.badgePadding)
                .infinityFrame(axis: .horizontal, alignment: .leading)
                .background { Fade(position: .top).frame(height: Metrics.fadeHeight) }
        }
    }

    var missingImageBadge: some View {
        Circle()
            .fill(DesignSystem.Color.bgTransparentPrimary)
            .frame(size: CGSize(bothDimensions: Metrics.fallbackBadgeSize))
            .overlay {
                DesignSystem.Icons.Error.filled20.image
                    .renderingMode(.template)
                    .resizable()
                    .frame(size: CGSize(bothDimensions: Metrics.fallbackGlyphSize))
                    .foregroundStyle(DesignSystem.Color.iconTertiary)
            }
    }

    var details: some View {
        VStack(alignment: .leading, spacing: Metrics.detailsSpacing) {
            Text(model.title)
                .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textPrimary)
                .lineLimit(1)

            if let valueText = model.valueText {
                Text(valueText)
                    .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textSecondary)
                    .lineLimit(1)
            }
        }
    }
}

// MARK: - Metrics

/// Not private: `Skeleton` reads the shared values so the grid does not jump when the content arrives.
extension CollectiblesPrizeCard {
    enum Metrics {
        static let artworkAspectRatio: CGFloat = 179 / 228
        static let cornerRadius: CGFloat = 20
        static let contentSpacing: CGFloat = 8
        static let detailsSpacing: CGFloat = 2
        static let badgePadding: CGFloat = 16
        static let fadeHeight: CGFloat = 56
        static let fallbackBadgeSize: CGFloat = 40
        static let fallbackGlyphSize: CGFloat = 20
    }

    enum Constants {
        static let fadeDuration: TimeInterval = 0.3
    }
}

// MARK: - Previews

#Preview {
    ZStack {
        DesignSystem.Color.bgPrimary.ignoresSafeArea()

        HStack(alignment: .top, spacing: 12) {
            CollectiblesPrizeCard(model: .init(id: "1", title: "Charizard", gradeText: "PSA 9", valueText: "$4,000", imageURL: nil))
            CollectiblesPrizeCard(model: .init(id: "2", title: "Pikachu", gradeText: nil, valueText: nil, imageURL: nil))
        }
        .padding(.horizontal, 16)
    }
}
