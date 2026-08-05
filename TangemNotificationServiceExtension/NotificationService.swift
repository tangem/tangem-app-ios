//
//  NotificationService.swift
//  TangemNotificationServiceExtension
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import UserNotifications

/// The app's single Notification Service Extension. Offers each incoming push to an ordered chain of
/// ``NotificationServiceHandling`` instances; the first to claim it takes over `contentHandler`, and if
/// none does the original content is delivered unchanged. iOS allows only one NSE per app, so new
/// consumers join the chain rather than becoming separate targets.
final class NotificationService: UNNotificationServiceExtension {
    private let handlers = NotificationServiceHandlerFactory.makeHandlers()

    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
        for handler in handlers {
            if handler.didReceive(request, withContentHandler: contentHandler) {
                return
            }
        }

        contentHandler(request.content)
    }

    override func serviceExtensionTimeWillExpire() {
        // The API gives no way to tell which push is expiring, so notify every handler and let the one
        // actually processing a push flush its best-effort content. Avoids tracking a single "current
        // owner" that a reused/overlapping extension instance could clobber.
        handlers.forEach { $0.serviceExtensionTimeWillExpire() }
    }
}
