//
//  CarouselNewsView.swift
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
import TangemLocalization

struct CarouselNewsView: View {
    let itemsState: LoadingResult<[CarouselNewsItem], Never>
    let onAllNewsTap: (() -> Void)?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Layout.cardSpacing) {
                ForEach(displayItems, id: \.id) { item in
                    CarouselNewsCardView(item: item, isLoading: itemsState.isLoading)
                }

                if !itemsState.isLoading, onAllNewsTap != nil {
                    allNewsCard
                }
            }
            .padding(.horizontal, Layout.defaultHorizontalInset)
        }
    }

    init(itemsState: LoadingResult<[CarouselNewsItem], Never>, onAllNewsTap: (() -> Void)? = nil) {
        self.itemsState = itemsState
        self.onAllNewsTap = onAllNewsTap
    }

    // MARK: - Computed Properties

    private var displayItems: [CarouselNewsItem] {
        if itemsState.isLoading {
            return Array(CarouselNewsItem.dummyItems.prefix(Layout.maxCardsCount))
        } else if let items = itemsState.value {
            return Array(items.prefix(Layout.maxCardsCount))
        } else {
            return []
        }
    }

    // MARK: - Components

    private var allNewsCard: some View {
        Button(action: {
            onAllNewsTap?()
        }) {
            VStack(spacing: Layout.AllNewsCard.verticalSpacing) {
                iconView

                FixedSpacer(height: Layout.AllNewsCard.spacingAfterIcon)

                Text(Localization.newsAllNews)
                    .style(Fonts.Bold.title3, color: Colors.Text.primary1)

                FixedSpacer(height: Layout.AllNewsCard.spacingAfterTitle)

                Text(Localization.newsStayInTheLoop)
                    .style(Fonts.Regular.footnote, color: Colors.Text.secondary)
            }
            .frame(width: Layout.MainCard.width, height: Layout.MainCard.height)
            .defaultRoundedBackground(
                with: Colors.Background.action,
                verticalPadding: Layout.MainCard.padding,
                horizontalPadding: Layout.MainCard.padding,
                cornerRadius: Layout.MainCard.cornerRadius
            )
        }
        .buttonStyle(.plain)
    }

    private var iconView: some View {
        Assets.Markets.moreNews
            .image
            .resizable()
            .renderingMode(.original)
            .frame(size: Layout.AllNewsCard.iconImageSize)
    }
}

private extension CarouselNewsView {
    enum Layout {
        static let maxCardsCount: Int = 5
        static let cardSpacing: CGFloat = 8
        static let defaultHorizontalInset: CGFloat = 16

        enum MainCard {
            static let width: CGFloat = 228
            static let height: CGFloat = 136
            static let padding: CGFloat = 14
            static let cornerRadius: CGFloat = 14
        }

        enum AllNewsCard {
            static let verticalSpacing: CGFloat = .zero
            static let spacingAfterIcon: CGFloat = 16
            static let spacingAfterTitle: CGFloat = 4
            static let iconSize: CGSize = .init(width: 48, height: 48)
            static let iconImageSize: CGSize = .init(width: 48, height: 48)
            static let iconBackgroundColor: Color = Colors.Background.tertiary
            static let iconForegroundColor: Color = Colors.Icon.accent
        }
    }
}

// MARK: - CarouselNewsItem Dummy Items

private extension CarouselNewsItem {
    static let dummyItems: [CarouselNewsItem] = (0 ..< 5).map { index in
        CarouselNewsItem(
            id: "dummy-\(index)",
            title: "-------------",
            rating: "----",
            timeAgo: "----",
            tags: [],
            isRead: false,
            onTap: { _ in }
        )
    }
}

#if DEBUG
#Preview {
    VStack {
        // Loading state
        CarouselNewsView(
            itemsState: .loading,
            onAllNewsTap: {}
        )

        // Success state
        CarouselNewsView(
            itemsState: .success([
                CarouselNewsItem(
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
                ),
                CarouselNewsItem(
                    title: "Bitcoin reaches new all-time high amid institutional adoption",
                    rating: "8.2",
                    timeAgo: "2h ago",
                    tags: [
                        InfoChipItem(title: "BTC"),
                        InfoChipItem(title: "Market"),
                    ],
                    isRead: true,
                    onTap: { _ in }
                ),
                CarouselNewsItem(
                    title: "Ethereum 2.0 staking rewards increase significantly",
                    rating: "7.8",
                    timeAgo: "3h ago",
                    tags: [
                        InfoChipItem(title: "ETH"),
                        InfoChipItem(title: "Staking"),
                    ],
                    isRead: false,
                    onTap: { _ in }
                ),
            ]),
            onAllNewsTap: {}
        )

        Spacer(minLength: 0)
    }
    .padding(.vertical)
    .background(Colors.Background.secondary)
}
#endif
