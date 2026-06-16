//
//  TrendingCardNewsViewRedesign.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils
import TangemLocalization
import TangemUI
import TangemFoundation

struct TrendingCardNewsViewRedesign: View {
    let itemState: LoadingResult<TrendingCardNewsItem, Never>

    var body: some View {
        if itemState.isLoading {
            TrendingCardNewsSkeletonView()
                .allowsHitTesting(false)
        } else if let item = itemState.value {
            Button(action: { item.onTap(item.id) }) {
                contentView(for: item)
            }
            .buttonStyle(.plain)
        }
    }

    private func contentView(for item: TrendingCardNewsItem) -> some View {
        VStack(alignment: .leading, spacing: .zero) {
            HStack(spacing: .unit(.x2)) {
                NewsRatingViewRedesign(rating: "\(item.rating) • \(item.timeAgo)", isHighlighted: true)
                Text(Localization.feedTrendingNow)
                    .style(Font.Tangem.Caption12.semibold, color: .Tangem.Text.Neutral.primary)
            }

            FixedSpacer(height: .unit(.x2))

            Text(item.title)
                .multilineTextAlignment(.leading)
                .style(Font.Tangem.Heading20.semibold, color: .Tangem.Text.Neutral.primary)

            Spacer(minLength: .unit(.x4))

            InfoChipsRowView(chips: item.tags, alignment: .leading, style: .redesign)
        }
        .padding(.all, .unit(.x4))
        .infinityFrame(axis: .horizontal, alignment: .topLeading)
        .frame(minHeight: Layout.cardMinHeight)
        .background {
            Assets.Markets
                .trendingNewsBackground
                .image
                .resizable()
                .allowsHitTesting(false)
        }
        .cornerRadiusContinuous(.unit(.x6))
        .opacity(item.isRead ? 0.6 : 1.0)
    }
}

private extension TrendingCardNewsViewRedesign {
    enum Layout {
        static let cardMinHeight: CGFloat = 180
    }
}
