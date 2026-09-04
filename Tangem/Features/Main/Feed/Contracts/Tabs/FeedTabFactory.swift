//
//  FeedTabFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

protocol FeedTabFactory {
    func makeTab(navigation: any FeedRoutable) -> FeedTab

    func makeSearchTab(
        query: AnyPublisher<String, Never>,
        history: FeedSearchHistoryProvider,
        navigation: any FeedRoutable
    ) -> FeedSearchTab
}
