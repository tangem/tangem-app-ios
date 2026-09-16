//
//  FeedSearchProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

protocol FeedSearchProvider<Item> {
    associatedtype Item

    var statePublisher: AnyPublisher<FeedSearchProviderState<Item>, Never> { get }

    func search(_ query: String)
    func loadMore()
    func reset()
}

extension FeedSearchProvider {
    /// Pagination is opt-in: a provider that keeps the whole result set in memory has nothing to load.
    func loadMore() {}
}

enum FeedSearchProviderState<Item> {
    case loading
    case loaded([Item])
    case empty
    case failed
}
