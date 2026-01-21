//
//  CommonNewsReadStatusService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

final class CommonNewsReadStatusService: NewsReadStatusProvider {
    private var readNewsIds: Set<NewsId> = []
    private let readStatusDidChangeSubject: PassthroughSubject<[NewsId], Never> = .init()

    var readStatusDidChangePublisher: AnyPublisher<[NewsId], Never> {
        readStatusDidChangeSubject.eraseToAnyPublisher()
    }

    func markAsRead(newsId: NewsId) {
        let (inserted, _) = readNewsIds.insert(newsId)
        guard inserted else { return }
        readStatusDidChangeSubject.send(Array(readNewsIds))
    }

    func isRead(for newsId: NewsId) -> Bool {
        readNewsIds.contains(newsId)
    }

    func clear() {
        readNewsIds.removeAll()
        readStatusDidChangeSubject.send(Array(readNewsIds))
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
