//
//  InMemoryNewsReadStatusProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

final class InMemoryNewsReadStatusProvider: NewsReadStatusProvider {
    private var readNewsIds: Set<NewsId> = []
    private let readStatusChangedSubject = PassthroughSubject<NewsId, Never>()

    var readStatusChangedPublisher: AnyPublisher<NewsId, Never> {
        readStatusChangedSubject.eraseToAnyPublisher()
    }

    func markAsRead(newsId: NewsId) {
        guard !readNewsIds.contains(newsId) else { return }

        readNewsIds.insert(newsId)
        readStatusChangedSubject.send(newsId)
    }

    func isRead(for newsId: NewsId) -> Bool {
        readNewsIds.contains(newsId)
    }
}

// MARK: - Dependency injection

private struct NewsReadStatusProviderKey: InjectionKey {
    static var currentValue: NewsReadStatusProvider = InMemoryNewsReadStatusProvider()
}

extension InjectedValues {
    var newsReadStatusProvider: NewsReadStatusProvider {
        get { Self[NewsReadStatusProviderKey.self] }
        set { Self[NewsReadStatusProviderKey.self] = newValue }
    }
}
