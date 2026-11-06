//
//  NotificationBadgeService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol NotificationBadgeService: AnyObject {
    func initialize()
}

private struct NotificationBadgeServiceKey: InjectionKey {
    static var currentValue: NotificationBadgeService = CommonNotificationBadgeService()
}

extension InjectedValues {
    var notificationBadgeService: NotificationBadgeService {
        get { Self[NotificationBadgeServiceKey.self] }
        set { Self[NotificationBadgeServiceKey.self] = newValue }
    }
}
