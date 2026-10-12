//
//  FeedSearchHistoryProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

protocol FeedSearchHistoryProvider {
    var historyPublisher: AnyPublisher<FeedSearchHistory, Never> { get }

    func save(query: String)
    func remove(_ query: FeedRecentQuery)
    func clear()
}
