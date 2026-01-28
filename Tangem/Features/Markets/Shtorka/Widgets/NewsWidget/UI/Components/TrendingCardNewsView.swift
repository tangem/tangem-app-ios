//
//  TrendingCardNewsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils
import TangemLocalization
import TangemUI
import TangemFoundation

struct TrendingCardNewsItem: Identifiable, Equatable {
    let id: String
    let title: String
    let rating: String
    let timeAgo: String
    let tags: [InfoChipItem]
    let isRead: Bool
    @IgnoredEquatable var onTap: (String) -> Void

    init(
        id: String,
        title: String,
        rating: String,
        timeAgo: String,
        tags: [InfoChipItem],
        isRead: Bool = false,
        onTap: @escaping (String) -> Void
    ) {
        self.id = id
        self.title = title
        self.rating = rating
        self.timeAgo = timeAgo
        self.tags = tags
        self.isRead = isRead
        self.onTap = onTap
    }
}

struct TrendingCardNewsView: View {
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

    // MARK: - Content View

    private func contentView(for item: TrendingCardNewsItem) -> some View {
        VStack(spacing: Layout.MainCard.verticalSpacing) {
            trendingBadge
                .skeletonable(isShown: itemState.isLoading, radius: Layout.TrendingBadge.cornerRadius)

            FixedSpacer(height: Layout.Spacing.afterTrendingBadge)

            Text(item.title)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .style(Fonts.Bold.title3, color: Colors.Text.primary1)
                .skeletonable(isShown: itemState.isLoading, radius: Layout.Skeleton.cornerRadius)

            FixedSpacer(height: Layout.Spacing.afterTitle)

            NewsRatingView(rating: item.rating, timeAgo: item.timeAgo)
                .skeletonable(isShown: itemState.isLoading, radius: Layout.Skeleton.cornerRadius)

            FixedSpacer(height: Layout.Spacing.afterRating)

            InfoChipsRowView(chips: item.tags, alignment: .center)
                .skeletonable(isShown: itemState.isLoading, radius: Layout.Skeleton.cornerRadius)
        }
        .infinityFrame(axis: .horizontal, alignment: .center)
        .defaultRoundedBackground(
            with: Colors.Background.action,
            verticalPadding: Layout.MainCard.padding,
            horizontalPadding: Layout.MainCard.padding,
            cornerRadius: Layout.MainCard.cornerRadius
        )
        .overlay(alignment: .topTrailing) {
            // [REDACTED_TODO_COMMENT]
            /*
             Assets.Markets
                 .trendingNewsBackground
                 .image
                 .resizable()
                 .scaledToFit()
                 .infinityFrame(axis: .horizontal, alignment: .topTrailing)
                 .cornerRadius(Layout.MainCard.cornerRadius, corners: [.topRight])
                 .allowsHitTesting(false)
              */
        }
        .opacity(opacity(for: item))
        .padding(.horizontal, Layout.MainCard.defaultHorizontalInset)
    }

    // MARK: - Components

    private var trendingBadge: some View {
        VStack(alignment: .center, spacing: .zero) {
            Text(Localization.feedTrendingNow)
                .style(Fonts.Bold.caption1, color: Colors.Text.accent)
                .defaultRoundedBackground(
                    with: Colors.Text.accent.opacity(Layout.TrendingBadge.opacity),
                    verticalPadding: Layout.TrendingBadge.verticalPadding,
                    horizontalPadding: Layout.TrendingBadge.horizontalPadding,
                    cornerRadius: Layout.TrendingBadge.cornerRadius
                )
        }
    }

    private func opacity(for item: TrendingCardNewsItem) -> Double {
        (item.isRead && !itemState.isLoading) ? Layout.ReadState.opacity : 1.0
    }
}

private extension TrendingCardNewsView {
    enum Layout {
        enum MainCard {
            static let verticalSpacing: CGFloat = .zero
            static let defaultHorizontalInset: CGFloat = 16
            static let padding: CGFloat = 24
            static let cornerRadius: CGFloat = 14
        }

        enum Spacing {
            static let afterTrendingBadge: CGFloat = 12
            static let afterTitle: CGFloat = 8
            static let afterRating: CGFloat = 32
        }

        enum Shadow {
            static let colorOpacity: Double = 0.12
            static let radius: CGFloat = 16
            static let yOffset: CGFloat = 8
        }

        enum TrendingBadge {
            static let verticalPadding: CGFloat = 4
            static let horizontalPadding: CGFloat = 12
            static let cornerRadius: CGFloat = 16
            static let opacity: Double = 0.1
        }

        enum ReadState {
            static let opacity: Double = 0.6
        }

        enum Skeleton {
            static let cornerRadius: CGFloat = 4
        }
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

#if DEBUG
#Preview {
    VStack(spacing: 16) {
        // Loading state
        TrendingCardNewsView(itemState: .loading)

        // Success state
        TrendingCardNewsView(
            itemState: .success(
                TrendingCardNewsItem(
                    id: UUID().uuidString,
                    title: "Headline",
                    rating: "6.5",
                    timeAgo: "Time",
                    tags: [
                        InfoChipItem(title: "Tag"),
                        InfoChipItem(title: "Tag"),
                        InfoChipItem(title: "Tag"),
                        InfoChipItem(title: "+3"),
                    ],
                    isRead: false,
                    onTap: { _ in }
                )
            )
        )

        // Read state
        TrendingCardNewsView(
            itemState: .success(
                TrendingCardNewsItem(
                    id: UUID().uuidString,
                    title: "Headline",
                    rating: "6.5",
                    timeAgo: "Time",
                    tags: [
                        InfoChipItem(title: "Tag"),
                        InfoChipItem(title: "Tag"),
                        InfoChipItem(title: "Tag"),
                        InfoChipItem(title: "Tag"),
                        InfoChipItem(title: "Tag"),
                        InfoChipItem(title: "Tag"),
                        InfoChipItem(title: "Tag"),
                        InfoChipItem(title: "Tag"),
                    ],
                    isRead: true,
                    onTap: { _ in }
                )
            )
        )

        Spacer(minLength: .zero)
    }
    .padding()
    .background(Colors.Background.secondary)
}
#endif
