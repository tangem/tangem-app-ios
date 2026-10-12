//
//  FeedTabBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

protocol FeedTabBuilder {
    func makeTab(context: FeedContext) -> FeedTab

    func makeSearchTab(
        query: AnyPublisher<String, Never>,
        history: FeedSearchHistoryProvider,
        context: FeedContext
    ) -> FeedSearchTab
}
