//
//  TrendingCardNewsView.swift
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

struct TrendingCardNewsView: View {
    let itemState: LoadingResult<TrendingCardNewsItem, Never>

    var body: some View {
        if itemState.isLoading {
            TrendingCardNewsSkeletonView()
                .allowsHitTesting(false)
        } else if let item = itemState.value {
            SwiftUI.Button(action: { item.onTap(item.id) }) {
                contentView(for: item)
            }
            .buttonStyle(.plain)
        }
    }

    private func contentView(for item: TrendingCardNewsItem) -> some View {
        VStack(alignment: .leading, spacing: .zero) {
            HStack(spacing: 8) {
                NewsRatingViewRedesign(rating: "\(item.rating) • \(item.timeAgo)", isHighlighted: true)
                Text(Localization.feedTrendingNow)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textPrimary)
            }

            FixedSpacer(height: 8)

            Text(item.title)
                .multilineTextAlignment(.leading)
                .style(DesignSystem.Font.headingSmallToken, color: DesignSystem.Color.textPrimary)

            Spacer(minLength: 16)

            InfoChipsRowView(chips: item.tags, alignment: .leading, style: .redesign)
        }
        .padding(.all, 16)
        .infinityFrame(axis: .horizontal, alignment: .topLeading)
        .frame(minHeight: Layout.cardMinHeight)
        .background {
            Assets.Markets
                .trendingNewsBackground
                .image
                .resizable()
                .allowsHitTesting(false)
        }
        .cornerRadiusContinuous(24)
        .opacity(item.isRead ? 0.6 : 1.0)
    }
}

private extension TrendingCardNewsView {
    enum Layout {
        static let cardMinHeight: CGFloat = 180
    }
}
