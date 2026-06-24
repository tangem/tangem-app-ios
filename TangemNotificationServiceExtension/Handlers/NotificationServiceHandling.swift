//
//  NotificationServiceHandling.swift
//  TangemNotificationServiceExtension
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import UserNotifications

/// A single link in the notification-processing chain inside the (one and only) Notification Service
/// Extension. iOS allows exactly one NSE per app and hands it a single `contentHandler` per push, so
/// every service that needs extension-side processing must coexist here. Each handler is offered the
/// incoming push and either claims it or passes it along.
protocol NotificationServiceHandling {
    /// Offers the incoming notification to the handler.
    ///
    /// - Returns: `true` if the handler recognized the push as its own and took ownership of
    ///   `contentHandler` (it will call it, possibly asynchronously). `false` if the push doesn't
    ///   belong to this handler — the chain continues to the next handler and `contentHandler` is
    ///   left untouched.
    func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) -> Bool

    /// Forwarded from `UNNotificationServiceExtension.serviceExtensionTimeWillExpire()` to the handler
    /// that currently owns the push, so it can deliver its best-effort content before termination.
    func serviceExtensionTimeWillExpire()
}
