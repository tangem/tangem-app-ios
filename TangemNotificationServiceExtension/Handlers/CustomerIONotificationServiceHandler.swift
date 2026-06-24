//
//  CustomerIONotificationServiceHandler.swift
//  TangemNotificationServiceExtension
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import UserNotifications
import CioMessagingPush
import CioMessagingPushFCM

/// Handles Customer.io rich pushes in the extension so the SDK can record the `delivered` metric and
/// compose rich content. Customer.io only claims pushes carrying its delivery headers
/// (`CIO-Delivery-ID` / `CIO-Delivery-Token`) and reports `false` for everything else, which maps
/// directly onto ``NotificationServiceHandling``'s claim-or-passthrough contract.
final class CustomerIONotificationServiceHandler {
    private lazy var messagingPush: MessagingPushInstance? = makeMessagingPush()

    private func makeMessagingPush() -> MessagingPushInstance? {
        guard
            let cdpApiKey = AppGroupSharedStorage.customerIOCdpApiKey,
            !cdpApiKey.isEmpty
        else {
            return nil
        }

        let config = MessagingPushConfigBuilder(cdpApiKey: cdpApiKey)
            .region(.EU)
            .autoTrackPushEvents(true)
            .logLevel(.error)
            .build()

        return MessagingPushFCM.initializeForExtension(withConfig: config)
    }
}

// MARK: - NotificationServiceHandling

extension CustomerIONotificationServiceHandler: NotificationServiceHandling {
    func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) -> Bool {
        guard let messagingPush else {
            return false
        }

        return messagingPush.didReceive(request, withContentHandler: contentHandler)
    }

    func serviceExtensionTimeWillExpire() {
        messagingPush?.serviceExtensionTimeWillExpire()
    }
}
