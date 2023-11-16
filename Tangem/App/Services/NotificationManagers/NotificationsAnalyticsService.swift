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
    private weak var contextDataProvider: AnalyticsContextDataProvider?

    private var subscription: AnyCancellable?
    private var alreadyTrackedEvents: Set<Analytics.Event> = []

    init() {}

    func setup(with notificationManager: NotificationManager, contextDataProvider: AnalyticsContextDataProvider?) {
        self.notificationManager = notificationManager
        self.contextDataProvider = contextDataProvider

        bind()
    }

    private func bind() {
        guard subscription == nil else {
            return
        }

        subscription = notificationManager?.notificationPublisher
            .debounce(for: 0.1, scheduler: DispatchQueue.main)
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: weakify(self, forFunction: NotificationsAnalyticsService.sendEventsIfNeeded(for:)))
    }

    private func sendEventsIfNeeded(for notifications: [NotificationViewInput]) {
        notifications.forEach(sendEventIfNeeded(for:))
    }

    private func sendEventIfNeeded(for notification: NotificationViewInput) {
        guard let analyticsEvent = notification.settings.event.analyticsEvent else {
            return
        }

        var notificationParams = notification.settings.event.analyticsParams
        if let contextData = contextDataProvider?.getAnalyticsContextData() {
            notificationParams.merge(contextData.analyticsParams, uniquingKeysWith: { old, new in old })
        }

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
