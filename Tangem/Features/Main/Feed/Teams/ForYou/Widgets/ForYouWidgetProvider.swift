//
//  ForYouWidgetProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

final class ForYouWidgetProvider {
    private weak var router: FeedWidgetsRoutable?

    init(router: FeedWidgetsRoutable) {
        self.router = router
    }
}

// MARK: - FeedWidgetProvider

extension ForYouWidgetProvider: FeedWidgetProvider {
    var widgetPublisher: AnyPublisher<FeedWidget?, Never> {
        .just(output: .forYou)
    }

    func select() {
        router?.openForYou()
    }
}
