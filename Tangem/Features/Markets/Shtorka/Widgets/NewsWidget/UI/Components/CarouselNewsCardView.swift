//
//  CarouselNewsCardView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils
import TangemUI
import TangemFoundation

struct CarouselNewsItem: Identifiable, Equatable {
    let id: String
    let title: String
    let rating: String
    let timeAgo: String
    let tags: [InfoChipItem]
    let isRead: Bool
    @IgnoredEquatable var onTap: (String) -> Void

    init(
        id: String = UUID().uuidString,
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

struct CarouselNewsCardView: View {
    let item: CarouselNewsItem
    let isLoading: Bool

    var body: some View {
        Button(action: {
            item.onTap(item.id)
        }) {
            contentView(for: item)
                .frame(width: Layout.MainCard.width, height: Layout.MainCard.height)
                .defaultRoundedBackground(
                    with: Colors.Background.action,
                    verticalPadding: Layout.MainCard.padding,
                    horizontalPadding: Layout.MainCard.padding,
                    cornerRadius: Layout.MainCard.cornerRadius
                )
                .opacity(opacity())
        }
        .buttonStyle(.plain)
        .allowsHitTesting(!isLoading)
    }

    // MARK: - Content View

    private func contentView(for item: CarouselNewsItem) -> some View {
        VStack(spacing: Layout.MainCard.verticalSpacing) {
            HStack {
                NewsRatingView(rating: item.rating, timeAgo: item.timeAgo)
                    .skeletonable(isShown: isLoading, radius: Layout.Skeleton.cornerRadius)

                Spacer()
            }

            FixedSpacer(height: Layout.Spacing.afterRating)

            Text(item.title)
                .multilineTextAlignment(.leading)
                .style(Fonts.Bold.body, color: Colors.Text.primary1)
                .infinityFrame(axis: .horizontal, alignment: .leading)
                .skeletonable(isShown: isLoading, radius: Layout.Skeleton.cornerRadius)

            Spacer(minLength: .zero)

            InfoChipsView(chips: item.tags, alignment: .leading)
                .skeletonable(isShown: isLoading, radius: Layout.Skeleton.cornerRadius)
        }
    }

    private func opacity() -> Double {
        if isLoading {
            return 1.0
        } else {
            return item.isRead ? Layout.ReadState.opacity : 1.0
        }
    }
}

extension CarouselNewsCardView {
    enum Layout {
        enum MainCard {
            static let verticalSpacing: CGFloat = .zero
            static let padding: CGFloat = 14
            static let cornerRadius: CGFloat = 14
            static let width: CGFloat = 228
            static let height: CGFloat = 136
        }

        enum Spacing {
            static let afterRating: CGFloat = 8
            static let afterTitle: CGFloat = 16
        }

        enum Shadow {
            static let colorOpacity: Double = 0.05
            static let radius: CGFloat = 4
            static let yOffset: CGFloat = 8
        }

        enum ReadState {
            static let opacity: Double = 0.6
        }

        enum Skeleton {
            static let cornerRadius: CGFloat = 8
        }
    }
}

// MARK: - CarouselNewsItem Placeholder

private extension CarouselNewsItem {
    static let placeholder: CarouselNewsItem = .init(
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
    VStack(alignment: .center, spacing: 16) {
        // Loading state
        HStack {
            CarouselNewsCardView(item: .placeholder, isLoading: true)

            Spacer(minLength: .zero)
        }

        // Success state
        HStack {
            CarouselNewsCardView(
                item: CarouselNewsItem(
                    title: "SEC delays decisions on ETH-staking ETFs and spot XRP/SOL funds",
                    rating: "6.5",
                    timeAgo: "1h ago",
                    tags: [
                        InfoChipItem(title: "Regulation"),
                        InfoChipItem(title: "+2"),
                    ],
                    isRead: false,
                    onTap: { _ in }
                ),
                isLoading: false
            )

            Spacer(minLength: .zero)
        }

        // Read state
        HStack {
            CarouselNewsCardView(
                item: CarouselNewsItem(
                    title: "SEC delays decisions on ETH-staking ETFs and spot XRP/SOL funds",
                    rating: "6.5",
                    timeAgo: "1h ago",
                    tags: [
                        InfoChipItem(title: "Regulation"),
                        InfoChipItem(title: "+2"),
                    ],
                    isRead: true,
                    onTap: { _ in }
                ),
                isLoading: false
            )

            Spacer(minLength: .zero)
        }

        Spacer(minLength: .zero)
    }
    .padding()
    .background(Colors.Background.secondary)
}
#endif
