//
//  FeedTabsFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

enum FeedTabsFactory {
    static func makeFactories() -> [any FeedTabFactory] {
        [
            CryptoFeedTabFactory(),
            PredictionsFeedTabFactory(),
        ]
    }
}
