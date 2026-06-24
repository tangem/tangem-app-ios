//
//  NotificationServiceHandlerFactory.swift
//  TangemNotificationServiceExtension
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

/// Builds the ordered chain of notification handlers. This is the single place to register a new
/// extension-side push consumer (e.g. an FCM rich-content helper): append it to the array. Order
/// matters only when more than one handler could claim the same push — the first claimer wins.
enum NotificationServiceHandlerFactory {
    static func makeHandlers() -> [NotificationServiceHandling] {
        [
            CustomerIONotificationServiceHandler(),
        ]
    }
}
