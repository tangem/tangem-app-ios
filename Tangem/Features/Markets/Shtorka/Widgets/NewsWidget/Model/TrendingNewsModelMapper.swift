//
//  TrendingNewsModelMapper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import TangemUI
import BlockchainSdk

// MARK: - TrendingNewsModelMapper

struct TrendingNewsModelMapper {
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale.current
        return formatter
    }()

    private let iconBuilder: IconURLBuilder = .init()

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale.current
        return formatter
    }()

    func mapToNewsModel(from response: TrendingNewsResponse.Item, isRead: Bool) -> TrendingNewsModel {
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

    // MARK: - Private Helpers

    private func formatScore(_ score: Double) -> String {
        String(format: "%.1f", score)
    }

    private func formatTimeAgo(from date: Date) -> String {
        let now = Date()
        let calendar = Calendar.current
        let isToday = calendar.isDateInToday(date)

        let diffInSeconds = now.timeIntervalSince(date)
        let diffInMinutes = Int(diffInSeconds / 60)
        let diffInHours = Int(diffInSeconds / 3600)

        if diffInMinutes < 1 {
            return Localization.newsPublishedMinutesAgo(1)
        }

        if diffInMinutes < 60 {
            return Localization.newsPublishedMinutesAgo(diffInMinutes)
        }

        if diffInHours < 12, isToday {
            return Localization.newsPublishedHoursAgo(diffInHours)
        }

        if isToday {
            let timeString = Self.timeFormatter.string(from: date)
            return String(format: "%@, %@", Localization.commonToday, timeString)
        }

        return Self.dateFormatter.string(from: date)
    }

    private func buildTags(categories: [NewsCategory], tokens: [RelatedToken]) -> [InfoChipItem] {
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
