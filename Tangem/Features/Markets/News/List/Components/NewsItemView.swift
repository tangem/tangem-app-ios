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

                Text(AppConstants.dotSign)
                    .style(Fonts.Bold.footnote, color: Color.Tangem.Text.Neutral.tertiary)

                Text(viewModel.relativeTime)
                    .style(Fonts.Regular.footnote, color: Color.Tangem.Text.Neutral.tertiary)
            }

            // Title (max 2 lines)
            Text(viewModel.title)
                .style(Fonts.Bold.title3, color: Color.Tangem.Text.Neutral.primary)
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
                .style(Fonts.Bold.footnote, color: Color.Tangem.Text.Neutral.primary)
        }
    }

    private var tagsChips: some View {
        var chips: [InfoChipItem] = []

        if !viewModel.category.isEmpty {
            chips.append(InfoChipItem(title: viewModel.category))
        }

        chips += viewModel.relatedTokens.map {
            InfoChipItem(id: $0.id, title: $0.symbol, leadingIcon: .url($0.iconURL))
        }

        return InfoChipsView(chips: chips, alignment: .leading)
    }
}
