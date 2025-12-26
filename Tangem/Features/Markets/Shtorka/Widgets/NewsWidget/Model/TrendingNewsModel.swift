//
//  TrendingNewsModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

// MARK: - TrendingNewsModel

struct TrendingNewsModel: Identifiable, Hashable {
    let id: NewsId
    let createdAt: Date
    let score: Double
    let language: String?
    let isTrending: Bool
    let newsUrl: String
    let categories: [NewsCategory]
    let relatedTokens: [RelatedToken]
    let title: String
    let isRead: Bool
}
