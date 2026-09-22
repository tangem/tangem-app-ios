//
//  FeedWidgetProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

protocol FeedWidgetProvider: AnyObject {
    var widgetPublisher: AnyPublisher<FeedWidget?, Never> { get }

    func refresh()
    func select()
}

extension FeedWidgetProvider {
    func refresh() {}
}
