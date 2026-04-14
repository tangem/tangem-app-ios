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
        Button(action: {
            if let item = itemState.value {
                item.onTap(item.id)
            }
        }) {
            Group {
                if let item = itemState.value {
                    contentView(for: item)
                } else {
                    contentView(for: .placeholder)
                }
            }
        }
        .buttonStyle(.plain)
        .allowsHitTesting(!itemState.isLoading)
    }

    private func contentView(for item: TrendingCardNewsItem) -> some View {
        VStack(alignment: .leading, spacing: .zero) {
            HStack(spacing: .unit(.x2)) {
                NewsRatingViewRedesign(rating: item.rating, isHighlighted: true)
                Text(Localization.feedTrendingNow)
                    .style(.Tangem.Caption12.semibold, color: .Tangem.Text.Neutral.primary)
            }
            .skeletonable(isShown: itemState.isLoading, radius: Layout.skeletonCornerRadius)

            FixedSpacer(height: .unit(.x2))

            Text(item.title)
                .multilineTextAlignment(.leading)
                .style(.Tangem.Heading20.semibold, color: .Tangem.Text.Neutral.primary)
                .infinityFrame(axis: .horizontal, alignment: .leading)
                .skeletonable(isShown: itemState.isLoading, radius: Layout.skeletonCornerRadius)

            FixedSpacer(height: .unit(.x4))

            Text(item.timeAgo)
                .style(.Tangem.Caption12.semibold, color: .Tangem.Text.Neutral.secondary)
                .skeletonable(isShown: itemState.isLoading, radius: Layout.skeletonCornerRadius)

            FixedSpacer(height: 18.0)

            InfoChipsRowView(chips: item.tags, alignment: .leading, style: .redesign)
                .skeletonable(isShown: itemState.isLoading, radius: Layout.skeletonCornerRadius)
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
        .cornerRadiusContinuous(.unit(.x5))
        .opacity(opacity(for: item))
        .padding(.horizontal, .unit(.x4))
    }

    private func opacity(for item: TrendingCardNewsItem) -> Double {
        (item.isRead && !itemState.isLoading) ? 0.6 : 1.0
    }
}

private extension TrendingCardNewsViewRedesign {
    enum Layout {
        static let cardMinHeight: CGFloat = 180
        static let skeletonCornerRadius: CGFloat = .unit(.x4)
    }
}

// MARK: - TrendingCardNewsItem Placeholder

private extension TrendingCardNewsItem {
    static let placeholder: TrendingCardNewsItem = .init(
        id: UUID().uuidString,
        title: "-------------------------",
        rating: "-----",
        timeAgo: "-----",
        tags: [
            .init(title: "--------"),
            .init(title: "----------"),
        ],
        isRead: false,
        onTap: { _ in }
    )
}
