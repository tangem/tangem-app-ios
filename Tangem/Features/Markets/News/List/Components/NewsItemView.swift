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
    let onTap: () -> Void

    private var textColor: Color {
        viewModel.isRead
            ? Color.Tangem.Text.Neutral.tertiary
            : Color.Tangem.Text.Neutral.primary
    }

    var body: some View {
        Button(action: onTap) {
            content
        }
        .buttonStyle(.scaled())
    }

    private var content: some View {
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
        .background(Color.Tangem.Surface.level4)
        .cornerRadius(14)
    }

    private var scoreBadge: some View {
        NewsScoreBadgeView(score: viewModel.score, textColor: textColor)
    }
}
