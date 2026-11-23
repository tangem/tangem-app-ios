//
//  NotificationBadgeApplier.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import UserNotifications

protocol NotificationBadgeApplier {
    func apply(count: Int) async throws
}

struct UserNotificationCenterBadgeApplier: NotificationBadgeApplier {
    func apply(count: Int) async throws {
        try await UNUserNotificationCenter.current().setBadgeCount(count)
    }
}
