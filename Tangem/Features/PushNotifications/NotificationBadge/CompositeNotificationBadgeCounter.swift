//
//  CompositeNotificationBadgeCounter.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import CombineExt
import TangemFoundation

struct CompositeNotificationBadgeCounter {
    private let counters: [NotificationBadgeCounter]

    init(counters: [NotificationBadgeCounter]) {
        self.counters = counters
    }
}

// MARK: - NotificationBadgeCounter protocol conformance

extension CompositeNotificationBadgeCounter: NotificationBadgeCounter {
    var notificationBadgeCountPublisher: AnyPublisher<Int, Never> {
        guard counters.isNotEmpty else {
            return .just(output: 0)
        }

        let countPublishers = counters.map { counter in
            counter.notificationBadgeCountPublisher.handleEvents(receiveOutput: { count in
                NotificationBadgeLogger.info("\(counter) emits notification badge count \(count)")
            })
            // For safety reason if one of counter doesn't emit at all
            .prepend(0)
        }

        return countPublishers
            .combineLatest()
            .map { $0.reduce(0, +) }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
}
