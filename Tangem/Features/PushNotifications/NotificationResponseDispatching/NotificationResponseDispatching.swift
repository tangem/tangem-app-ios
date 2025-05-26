//
//  NotificationResponseDispatching.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

protocol NotificationResponseDispatching {
    func register(subscriber: PushNotificationSubscriber)
    func unregister(subscriber: PushNotificationSubscriber)
}
