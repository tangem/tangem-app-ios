//
//  FeedWidgetsRegistry.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

enum FeedWidgetsRegistry {
    static func makeProviders(router: FeedWidgetsRoutable) -> [FeedWidgetProvider] {
        [
            ForYouWidgetProvider(router: router),
            AddAccountWidgetProvider(router: router),
        ]
    }
}
