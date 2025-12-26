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
    private let item: CarouselNewsItem

    init(item: CarouselNewsItem) {
        self.item = item
    }

    var body: some View {
        Button(action: {
            item.onTap(item.id)
        }) {
            VStack(spacing: Layout.MainCard.verticalSpacing) {
                HStack {
                    NewsRatingView(rating: item.rating, timeAgo: item.timeAgo)

                    Spacer()
                }

                FixedSpacer(height: Layout.Spacing.afterRating)

                Text(item.title)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .style(Fonts.Bold.body, color: Colors.Text.primary1)

                Spacer(minLength: .zero)

                InfoChipsView(chips: item.tags, alignment: .leading)
            }
            .frame(width: Layout.MainCard.width, height: Layout.MainCard.height)
            .defaultRoundedBackground(
                with: Colors.Background.action,
                verticalPadding: Layout.MainCard.padding,
                horizontalPadding: Layout.MainCard.padding,
                cornerRadius: Layout.MainCard.cornerRadius
            )
            .shadow(
                color: Colors.Icon.secondary.opacity(Layout.Shadow.colorOpacity),
                radius: Layout.Shadow.radius,
                y: Layout.Shadow.yOffset
            )
            .opacity(item.isRead ? Layout.ReadState.opacity : 1.0)
        }
        .buttonStyle(.plain)
    }
}

extension CarouselNewsCardView {
    enum Layout {
        enum MainCard {
            static let verticalSpacing: CGFloat = .zero
            static let padding: CGFloat = 14
            static let cornerRadius: CGFloat = 22
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
    }
}

#if DEBUG
#Preview {
    VStack(alignment: .center, spacing: 16) {
        HStack {
            CarouselNewsCardView(
                item: CarouselNewsItem(
                    title: "SEC delays decisions on ETH-staking ETFs and spot XRP/SOL funds",
                    rating: "6.5",
                    timeAgo: "1h ago",
                    tags: [
                        InfoChipItem(title: "Regulation"),
                        InfoChipItem(title: "XRP", leadingIcon: .image(Image(systemName: "bitcoinsign.circle.fill"))),
                        InfoChipItem(title: "+2"),
                    ],
                    isRead: false,
                    onTap: { _ in }
                )
            )

            Spacer(minLength: .zero)
        }

        HStack {
            CarouselNewsCardView(
                item: CarouselNewsItem(
                    title: "SEC delays decisions on ETH-staking ETFs and spot XRP/SOL funds",
                    rating: "6.5",
                    timeAgo: "1h ago",
                    tags: [
                        InfoChipItem(title: "Regulation"),
                        InfoChipItem(title: "XRP", leadingIcon: .image(Image(systemName: "bitcoinsign.circle.fill"))),
                        InfoChipItem(title: "+2"),
                    ],
                    isRead: true,
                    onTap: { _ in }
                )
            )

            Spacer(minLength: .zero)
        }

        Spacer(minLength: .zero)
    }
    .padding()
    .background(Colors.Background.secondary)
}
#endif
