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
        legacyContentView(for: item)
    }

    // MARK: - Legacy

    private func legacyContentView(for item: TrendingCardNewsItem) -> some View {
        VStack(spacing: LegacyLayout.MainCard.verticalSpacing) {
            trendingBadge
                .skeletonable(isShown: itemState.isLoading, radius: LegacyLayout.TrendingBadge.cornerRadius)

            FixedSpacer(height: LegacyLayout.Spacing.afterTrendingBadge)

            Text(item.title)
                .multilineTextAlignment(.center)
                .style(Fonts.Bold.title3, color: Colors.Text.primary1)
                .skeletonable(isShown: itemState.isLoading, radius: LegacyLayout.Skeleton.cornerRadius)

            FixedSpacer(height: LegacyLayout.Spacing.afterTitle)

            NewsRatingView(rating: item.rating, timeAgo: item.timeAgo)
                .skeletonable(isShown: itemState.isLoading, radius: LegacyLayout.Skeleton.cornerRadius)

            FixedSpacer(height: LegacyLayout.Spacing.afterRating)

            InfoChipsRowView(chips: item.tags, alignment: .center)
                .skeletonable(isShown: itemState.isLoading, radius: LegacyLayout.Skeleton.cornerRadius)
        }
        .infinityFrame(axis: .horizontal, alignment: .center)
        .defaultRoundedBackground(
            with: Colors.Background.action,
            verticalPadding: LegacyLayout.MainCard.padding,
            horizontalPadding: LegacyLayout.MainCard.padding,
            cornerRadius: LegacyLayout.MainCard.cornerRadius
        )
        .opacity(opacity(for: item))
        .padding(.horizontal, LegacyLayout.MainCard.defaultHorizontalInset)
    }

    // MARK: - Components

    private var trendingBadge: some View {
        VStack(alignment: .center, spacing: .zero) {
            Text(Localization.feedTrendingNow)
                .style(Fonts.Bold.caption1, color: Colors.Text.accent)
                .defaultRoundedBackground(
                    with: Colors.Text.accent.opacity(LegacyLayout.TrendingBadge.opacity),
                    verticalPadding: LegacyLayout.TrendingBadge.verticalPadding,
                    horizontalPadding: LegacyLayout.TrendingBadge.horizontalPadding,
                    cornerRadius: LegacyLayout.TrendingBadge.cornerRadius
                )
        }
    }

    private func opacity(for item: TrendingCardNewsItem) -> Double {
        (item.isRead && !itemState.isLoading) ? LegacyLayout.ReadState.opacity : 1.0
    }
}

private extension TrendingCardNewsView {
    enum LegacyLayout {
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
