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
import TangemUIUtils

struct NewsQuickRecapView: View {
    let content: String

    var body: some View {
        redesignContent
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
        HStack(spacing: 4) {
            Assets.Glyphs.tripleSparkles.image
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .foregroundStyle(NewsHeaderGradient.linearGradient)

            Text(Localization.newsQuickRecap)
                .style(DesignSystem.Font.subheadingMediumToken, color: .clear)
                .overlay(
                    NewsHeaderGradient.linearGradient.mask(
                        Text(Localization.newsQuickRecap)
                            .style(DesignSystem.Font.subheadingMediumToken, color: .black)
                    )
                )
        }
    }

    private var redesignBody: some View {
        // Text has 8pt vertical padding around it; the leading 1pt line is overlaid such that it
        // matches only the text's natural height (no vertical padding zone), per latest design review.
        Text(content)
            .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 8)
            .padding(.leading, 8 + Constants.lineWidth + 12)
            .overlay(alignment: .leading) {
                Rectangle()
                    .fill(Constants.leadingLineColor)
                    .frame(width: Constants.lineWidth)
                    .padding(.leading, 8)
                    .padding(.vertical, 8)
            }
    }
}

private extension NewsQuickRecapView {
    enum Constants {
        static let titleBottomSpacing: CGFloat = 8
        static let lineWidth: CGFloat = 1
        /// Leading 1pt accent line matches the first stop of the shared Tangem AI brand gradient.
        static var leadingLineColor: Color {
            NewsHeaderGradient.stops.first?.color ?? .clear
        }
    }
}
