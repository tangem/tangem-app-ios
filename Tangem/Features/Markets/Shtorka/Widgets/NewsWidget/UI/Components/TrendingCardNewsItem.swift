//
//  TrendingCardNewsItem.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemFoundation
import TangemUI

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
