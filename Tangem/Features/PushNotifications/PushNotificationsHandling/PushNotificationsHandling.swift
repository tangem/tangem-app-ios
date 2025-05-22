//
//  PushNotificationsHandling.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import UserNotifications

protocol PushNotificationsHandling: UNUserNotificationCenterDelegate {}

// MARK: - Dependencies

private struct PushNotificationHandlingKey: InjectionKey {
    static var currentValue: PushNotificationsHandling = CommonPushNotificationsHandler()
}

extension InjectedValues {
    var pushNotificationsHandler: PushNotificationsHandling {
        handler
    }
    
    private var handler: PushNotificationsHandling {
        get { Self[PushNotificationHandlingKey.self] }
        set { Self[PushNotificationHandlingKey.self] = newValue }
    }
}
