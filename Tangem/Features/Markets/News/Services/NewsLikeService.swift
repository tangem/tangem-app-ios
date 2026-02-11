//
//  NewsLikeService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

protocol NewsLikeService: AnyObject {
    func isLiked(newsId: Int) -> Bool
    func toggleLike(newsId: Int)
}

final class InMemoryNewsLikeService: NewsLikeService {
    private var likedNewsIds: Set<Int> = []

    func isLiked(newsId: Int) -> Bool {
        likedNewsIds.contains(newsId)
    }

    func toggleLike(newsId: Int) {
        if likedNewsIds.contains(newsId) {
            likedNewsIds.remove(newsId)
        } else {
            likedNewsIds.insert(newsId)
        }
    }
}

// MARK: - Dependency Injection

private struct NewsLikeServiceKey: InjectionKey {
    static var currentValue: NewsLikeService = InMemoryNewsLikeService()
}

extension InjectedValues {
    var newsLikeService: NewsLikeService {
        get { Self[NewsLikeServiceKey.self] }
        set { Self[NewsLikeServiceKey.self] = newValue }
    }
}
