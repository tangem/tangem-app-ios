//
//  NewsPagerDataSource.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

@MainActor
protocol NewsPagerDataSource: AnyObject {
    var canFetchMore: Bool { get }
    func loadMoreNewsIds() async -> [Int]
}

// MARK: - Adapter for NewsDataProvider

final class NewsDataProviderPagerDataSource: NewsPagerDataSource {
    private weak var provider: NewsDataProvider?

    var canFetchMore: Bool {
        provider?.canFetchMore ?? false
    }

    init(provider: NewsDataProvider) {
        self.provider = provider
    }

    func loadMoreNewsIds() async -> [Int] {
        guard let provider, provider.canFetchMore else { return [] }

        return await withCheckedContinuation { continuation in
            var cancellable: AnyCancellable?

            cancellable = provider.eventPublisher
                .compactMap { event -> [Int]? in
                    switch event {
                    case .appendedItems(let items, _):
                        return items.map(\.id)
                    case .failedToFetchData:
                        return []
                    default:
                        return nil
                    }
                }
                .first()
                .sink { newIds in
                    cancellable?.cancel()
                    continuation.resume(returning: newIds)
                }

            provider.fetchMore()
        }
    }
}

// MARK: - Single News Data Source (for deeplinks/widgets with no pagination)

final class SingleNewsDataSource: NewsPagerDataSource {
    var canFetchMore: Bool { false }

    func loadMoreNewsIds() async -> [Int] {
        []
    }
}
