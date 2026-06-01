//
//  NewsQuickRecapView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemFoundation
import TangemLocalization
import TangemUI

struct NewsQuickRecapView: View {
    let content: String

    var body: some View {
        if FeatureProvider.isAvailable(.redesign) {
            redesignContent
        } else {
            legacyContent
        }
    }

    // MARK: - Redesign

    private var redesignContent: some View {
        VStack(alignment: .leading, spacing: .zero) {
            redesignTitle

            FixedSpacer(height: Constants.titleBottomSpacing)

            redesignBody
        }
    }

    private var redesignTitle: some View {
        HStack(spacing: SizeUnit.x1.value) {
            Assets.Glyphs.tripleSparkles.image
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: SizeUnit.x5.value, height: SizeUnit.x5.value)
                .foregroundStyle(NewsHeaderGradient.linearGradient)

            Text(Localization.newsQuickRecap)
                .style(.Tangem.Subheadline.medium, color: .clear)
                .overlay(
                    NewsHeaderGradient.linearGradient.mask(
                        Text(Localization.newsQuickRecap)
                            .style(.Tangem.Subheadline.medium, color: .black)
                    )
                )
        }
    }

    private var redesignBody: some View {
        // Text has 8pt vertical padding around it; the leading 1pt line is overlaid such that it
        // matches only the text's natural height (no vertical padding zone), per latest design review.
        Text(content)
            .style(.Tangem.Body16.regular, color: .Tangem.Text.Neutral.primary)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, .unit(.x2))
            .padding(.leading, .unit(.x2) + Constants.lineWidth + .unit(.x3))
            .overlay(alignment: .leading) {
                Rectangle()
                    .fill(Constants.leadingLineColor)
                    .frame(width: Constants.lineWidth)
                    .padding(.leading, .unit(.x2))
                    .padding(.vertical, .unit(.x2))
            }
    }

    // MARK: - Legacy

    private var legacyContent: some View {
        HStack(alignment: .top, spacing: 0) {
            Separator(height: .exact(2), color: Color.Tangem.Border.Neutral.primary, axis: .vertical)

            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Assets.Glyphs.quickRecap.image
                        .foregroundStyle(Color.Tangem.Fill.Status.accent)

                    Text(Localization.newsQuickRecap)
                        .style(Fonts.Bold.footnote, color: Color.Tangem.Text.Status.accent)
                }

                Text(content)
                    .style(Fonts.Regular.body, color: Color.Tangem.Text.Neutral.primary)
            }
            .padding(.leading, 16)
            .padding(.bottom, 8)
        }
    }
}

private extension NewsQuickRecapView {
    enum Constants {
        static let titleBottomSpacing: CGFloat = .unit(.x2)
        static let lineWidth: CGFloat = 1
        /// Leading 1pt accent line matches the first stop of the shared Tangem AI brand gradient.
        static var leadingLineColor: Color {
            NewsHeaderGradient.stops.first?.color ?? .clear
        }
    }
}
