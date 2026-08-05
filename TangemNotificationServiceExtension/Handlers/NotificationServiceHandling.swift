//
//  NotificationServiceHandling.swift
//  TangemNotificationServiceExtension
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import UserNotifications

/// One link in the extension's notification-processing chain. Each handler is offered the incoming push
/// and either claims it or passes it along.
protocol NotificationServiceHandling {
    /// Offers the push to the handler.
    /// - Returns: `true` if it claimed the push and took ownership of `contentHandler` (calling it,
    ///   possibly asynchronously); `false` to leave `contentHandler` untouched and continue the chain.
    func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) -> Bool

    /// Forwarded from `serviceExtensionTimeWillExpire()` to every handler; the one processing the current
    /// push flushes best-effort content before termination. A handler with no push in flight must no-op.
    func serviceExtensionTimeWillExpire()
}
