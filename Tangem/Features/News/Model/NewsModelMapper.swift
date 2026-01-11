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

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale.current
        formatter.unitsStyle = .full
        formatter.dateTimeStyle = .named
        return formatter
    }()

    private static let dateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.setLocalizedDateFormatFromTemplate("d MMM HH:mm")
        return formatter
    }()

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
                timeAgo: formatTimeAgo(from: item.createdAt),
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
            timeAgo: formatTimeAgo(from: item.createdAt),
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
            timeAgo: formatTimeAgo(from: item.createdAt),
            tags: buildTags(categories: item.categories, tokens: item.relatedTokens),
            isRead: item.isRead,
            onTap: onTap
        )
    }
}

// MARK: - Private Implementation

private extension NewsModelMapper {
    // MARK: - Private Helpers

    private func formatScore(_ score: Double) -> String {
        String(format: "%.1f", score)
    }

    private func formatTimeAgo(from date: Date) -> String {
        let now = Date()
        let hoursAgo = now.timeIntervalSince(date) / 3600
        if hoursAgo < 24 {
            return Self.relativeFormatter.localizedString(for: date, relativeTo: now)
        } else {
            return Self.dateTimeFormatter.string(from: date)
        }
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
}
