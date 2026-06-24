//
//  NotificationService.swift
//  TangemNotificationServiceExtension
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import UserNotifications

/// The app's single Notification Service Extension. It owns no provider-specific logic: it offers the
/// incoming push to an ordered chain of ``NotificationServiceHandling`` instances and lets the first
/// one that recognizes the push take over the system-provided `contentHandler`. If none claims it, the
/// original content is delivered unchanged.
///
/// This is what makes extension-side push handling fixable for the `delivered` metric (via the
/// Customer.io handler) while staying open to additional consumers — iOS permits only one NSE per app,
/// so flexibility lives in this chain rather than in multiple extension targets.
final class NotificationService: UNNotificationServiceExtension {
    private let handlers = NotificationServiceHandlerFactory.makeHandlers()
    private var claimingHandler: NotificationServiceHandling?

    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
        for handler in handlers {
            if handler.didReceive(request, withContentHandler: contentHandler) {
                claimingHandler = handler
                return
            }
        }

        contentHandler(request.content)
    }

    override func serviceExtensionTimeWillExpire() {
        claimingHandler?.serviceExtensionTimeWillExpire()
    }
}
