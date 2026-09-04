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

enum FeedSearchProviderState<Item> {
    case loading
    case loaded([Item])
    case empty
    case failed
}
