//
//  NotificationsAnalyticsService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

class NotificationsAnalyticsService {
    private var alreadyTrackedEvents: Set<Analytics.Event> = []
    private let userWalletId: UserWalletId

    init(userWalletId: UserWalletId) {
        self.userWalletId = userWalletId
    }

    func sendEventsIfNeeded(for notifications: [NotificationViewInput]) {
        notifications.forEach(sendEventIfNeeded(for:))
    }

    private func sendEventIfNeeded(for notification: NotificationViewInput) {
        let event = notification.settings.event
        guard let analyticsEvent = event.analyticsEvent else {
            return
        }

        let notificationParams = notification.settings.event.analyticsParams

        if event.isOneShotAnalyticsEvent, alreadyTrackedEvents.contains(analyticsEvent) {
            return
        }

        Analytics.log(
            event: analyticsEvent,
            params: notificationParams,
            contextParams: .userWallet(userWalletId)
        )

        if event.isOneShotAnalyticsEvent {
            alreadyTrackedEvents.insert(analyticsEvent)
        }
    }
}
