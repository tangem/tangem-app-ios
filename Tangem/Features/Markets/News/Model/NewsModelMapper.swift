//
//  NewsModelMapper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import TangemUI
import BlockchainSdk

// MARK: - NewsModelMapper

struct NewsModelMapper {
    private let iconBuilder: IconURLBuilder = .init()
    private let dateFormatter: NewsDateFormatter = .init()

    // MARK: - Implementation

    func mapToNewsModel(from response: NewsDTO.List.Item, isRead: Bool) -> TrendingNewsModel {
        TrendingNewsModel(
            id: String(response.id),
            createdAt: response.createdAt,
            score: response.score,
            language: response.language,
            isTrending: response.isTrending,
            newsUrl: response.newsUrl,
            categories: response.categories,
            relatedTokens: response.relatedTokens,
            title: response.title,
            isRead: isRead
        )
    }

    func mapCarouselNewsItem(
        from response: NewsDTO.List.Response,
        onTap: @escaping (String) -> Void
    ) -> [CarouselNewsItem] {
        response.items.map { item in
            CarouselNewsItem(
                id: String(item.id),
                title: item.title,
                rating: formatScore(item.score),
                timeAgo: dateFormatter.formatTimeAgo(from: item.createdAt),
                tags: buildTags(categories: item.categories, tokens: item.relatedTokens),
                isRead: false,
                onTap: onTap
            )
        }
    }

    func toTrendingCardNewsItem(
        from item: TrendingNewsModel,
        onTap: @escaping (String) -> Void
    ) -> TrendingCardNewsItem {
        TrendingCardNewsItem(
            id: item.id,
            title: item.title,
            rating: formatScore(item.score),
            timeAgo: dateFormatter.formatTimeAgo(from: item.createdAt),
            tags: buildTags(categories: item.categories, tokens: item.relatedTokens),
            isRead: item.isRead,
            onTap: onTap
        )
    }

    func toCarouselNewsItem(
        from item: TrendingNewsModel,
        onTap: @escaping (String) -> Void
    ) -> CarouselNewsItem {
        CarouselNewsItem(
            id: item.id,
            title: item.title,
            rating: formatScore(item.score),
            timeAgo: dateFormatter.formatTimeAgo(from: item.createdAt),
            tags: buildTags(categories: item.categories, tokens: item.relatedTokens),
            isRead: item.isRead,
            onTap: onTap
        )
    }

    func toNewsItemViewModel(from item: NewsDTO.List.Item) -> NewsItemViewModel {
        NewsItemViewModel(
            id: item.id,
            score: formatScore(item.score),
            category: item.categories.first?.name ?? "",
            relatedTokens: item.relatedTokens.map { token in
                NewsItemViewModel.RelatedToken(id: token.id, symbol: token.symbol)
            },
            title: truncateTitle(item.title, maxLength: Constants.maxTitleLength),
            relativeTime: dateFormatter.formatTimeAgo(from: item.createdAt),
            isTrending: item.isTrending,
            newsUrl: item.newsUrl
        )
    }
}

// MARK: - Private Implementation

private extension NewsModelMapper {
    // MARK: - Private Helpers

    private func formatScore(_ score: Double) -> String {
        String(format: "%.1f", score)
    }

    private func buildTags(
        categories: [NewsDTO.List.Category],
        tokens: [NewsDTO.List.RelatedToken]
    ) -> [InfoChipItem] {
        var tags: [InfoChipItem] = []

        tags.append(contentsOf: categories.map { category in
            InfoChipItem(title: category.name)
        })

        tags.append(contentsOf: tokens.map { token in
            InfoChipItem(
                title: token.symbol,
                leadingIcon: .url(iconBuilder.tokenIconURL(id: token.id, size: .small))
            )
        })

        return tags
    }

    private func truncateTitle(_ title: String, maxLength: Int) -> String {
        guard title.count > maxLength else { return title }
        return String(title.prefix(maxLength - 3)) + "..."
    }
}

// MARK: - Constants

private extension NewsModelMapper {
    enum Constants {
        static let maxTitleLength = 70
    }
}
