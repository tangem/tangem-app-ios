//
//  PushNotificationsEvents.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import UserNotifications

enum AuthorizationEvent {
    case granted
    case deniedOrUndetermined
    case failed(Error)
}

enum PushNotificationsEvent {
    case authorization(AuthorizationEvent)
    case receivedResponse(UNNotificationResponse)
}
