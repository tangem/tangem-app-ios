//
//  CommonNewsReadStatusService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

final class CommonNewsReadStatusService: NewsReadStatusProvider {
    private var readNewsIds: Set<NewsId> = []

    func markAsRead(newsId: NewsId) {
        readNewsIds.insert(newsId)
    }

    func isRead(for newsId: NewsId) -> Bool {
        readNewsIds.contains(newsId)
    }

    func clear() {
        readNewsIds.removeAll()
    }
}

// MARK: - Dependency injection

private struct NewsReadStatusProviderKey: InjectionKey {
    static var currentValue: NewsReadStatusProvider = CommonNewsReadStatusService()
}

extension InjectedValues {
    var newsReadStatusProvider: NewsReadStatusProvider {
        get { Self[NewsReadStatusProviderKey.self] }
        set { Self[NewsReadStatusProviderKey.self] = newValue }
    }
}
