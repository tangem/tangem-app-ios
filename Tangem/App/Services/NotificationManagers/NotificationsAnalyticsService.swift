//
//  NotificationsAnalyticsService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class NotificationsAnalyticsService {
    private weak var notificationManager: NotificationManager?

    private var subscription: AnyCancellable?
    private var alreadyTrackedEvents: Set<Analytics.Event> = []

    init() {}

    func setup(with notificationManager: NotificationManager) {
        self.notificationManager = notificationManager
        bind()
    }

    private func bind() {
        subscription = notificationManager?.notificationPublisher
            .receive(on: DispatchQueue.global())
            .sink(receiveValue: weakify(self, forFunction: NotificationsAnalyticsService.sendEventsIfNeeded(for:)))
    }

    private func sendEventsIfNeeded(for notifications: [NotificationViewInput]) {
        notifications.forEach(sendEventIfNeeded(for:))
    }

    private func sendEventIfNeeded(for notification: NotificationViewInput) {
        guard let analyticsEvent = notification.settings.event.analyticsEvent else {
            return
        }

        let notificationParams = notification.settings.event.analyticsParams

        switch notification.settings.event {
        case is WarningEvent:
            if alreadyTrackedEvents.contains(analyticsEvent) {
                return
            }

            alreadyTrackedEvents.insert(analyticsEvent)
            Analytics.log(event: analyticsEvent, params: notificationParams)
        case is TokenNotificationEvent:
            Analytics.log(event: analyticsEvent, params: notificationParams)
        default:
            return
        }
    }
}
