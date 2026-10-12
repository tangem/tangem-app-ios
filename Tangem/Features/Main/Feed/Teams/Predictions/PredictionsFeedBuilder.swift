//
//  PredictionsFeedBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

struct PredictionsFeedBuilder: FeedTabBuilder {
    func makeTab(context: FeedContext) -> FeedTab {
        .predictions
    }

    func makeSearchTab(
        query: AnyPublisher<String, Never>,
        history: FeedSearchHistoryProvider,
        context: FeedContext
    ) -> FeedSearchTab {
        .predictions
    }
}
