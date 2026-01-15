//
//  NewsItemView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct NewsItemView: View {
    let viewModel: NewsItemViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Score badge + Time
            HStack(spacing: 4) {
                scoreBadge

                Text("·")
                    .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

                Text(viewModel.relativeTime)
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
            }

            // Title (max 2 lines)
            Text(viewModel.title)
                .style(Fonts.Bold.title3, color: Colors.Text.primary1)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .padding(.bottom, 12)

            // Category + Related tokens chips
            tagsChips
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 16)
        .padding(.horizontal, 14)
        .background(Color.Tangem.Surface.level4)
        .cornerRadius(14)
    }

    private var scoreBadge: some View {
        HStack(spacing: 4) {
            ZStack {
                Circle()
                    .foregroundStyle(Color.Tangem.Graphic.Status.attention)
                    .frame(size: .init(bothDimensions: 12))
                Assets.star.image
                    .renderingMode(.template)
                    .resizable()
                    .frame(size: .init(bothDimensions: 7))
                    .foregroundStyle(Color.Tangem.Graphic.Neutral.primaryInverted)
            }

            Text(viewModel.score)
                .style(Fonts.Bold.footnote, color: Colors.Text.primary1)
        }
    }

    private var tagsChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                // Category chip
                if !viewModel.category.isEmpty {
                    NewsTagChipView(title: viewModel.category)
                }

                // Related tokens chips with icons
                ForEach(viewModel.relatedTokens) { token in
                    NewsTagChipView(title: token.symbol, iconURL: token.iconURL)
                }
            }
        }
    }
}

// MARK: - NewsTagChipView

private struct NewsTagChipView: View {
    let title: String
    var iconURL: URL?

    var body: some View {
        HStack(spacing: 4) {
            if let iconURL {
                IconView(url: iconURL, size: CGSize(bothDimensions: 16), forceKingfisher: true)
            }

            Text(title)
                .style(Fonts.Bold.caption1, color: Colors.Text.secondary)
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Colors.Control.unchecked)
        .cornerRadius(16)
    }
}
