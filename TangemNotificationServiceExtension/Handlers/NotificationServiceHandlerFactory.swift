//
//  NotificationServiceHandlerFactory.swift
//  TangemNotificationServiceExtension
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

/// Builds the ordered chain of notification handlers — the single place to register a new push
/// consumer. Order matters only when two handlers could claim the same push: the first wins.
enum NotificationServiceHandlerFactory {
    static func makeHandlers() -> [NotificationServiceHandling] {
        [
            CustomerIONotificationServiceHandler(),
        ]
    }
}
