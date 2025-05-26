//
//  PushNotificationSubscriber.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import UserNotifications

protocol PushNotificationSubscriber: AnyObject {
    @MainActor
    func handleResponse(_ response: UNNotificationResponse)
}
