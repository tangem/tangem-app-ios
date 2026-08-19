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
import CioInternalCommon

/// Handles Customer.io rich pushes so the SDK records the `delivered` metric and composes rich content.
/// The SDK claims only pushes carrying its delivery headers and returns `false` otherwise, matching
/// ``NotificationServiceHandling``'s claim-or-passthrough contract.
struct CustomerIONotificationServiceHandler: NotificationServiceHandling {
    /// Initialized once per extension process rather than per handler instance: iOS may build a fresh
    /// handler for each push within a reused process, and the Customer.io push instance is a singleton.
    private static let messagingPush: MessagingPushInstance? = makeMessagingPush()

    func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) -> Bool {
        guard let messagingPush = Self.messagingPush else {
            return false
        }

        return messagingPush.didReceive(request, withContentHandler: contentHandler)
    }

    func serviceExtensionTimeWillExpire() {
        Self.messagingPush?.serviceExtensionTimeWillExpire()
    }

    private static func makeMessagingPush() -> MessagingPushInstance? {
        #if DEBUG
        // Keep in sync with CustomerIOWrapper.configure(): the app disables Customer.io in debug builds
        // (AppEnvironment.isDebug is `#if DEBUG`), so the extension must not init the SDK or report
        // `delivered` metrics there either.
        return nil
        #else
        guard
            let cdpApiKey = CustomerIOConfigProvider.cdpApiKey,
            !cdpApiKey.isEmpty
        else {
            return nil
        }

        let config = MessagingPushConfigBuilder(cdpApiKey: cdpApiKey)
            .region(CustomerIOSharedConfiguration.region)
            .logLevel(CustomerIOSharedConfiguration.logLevel)
            .tangemPushDefaults()
            .build()

        return MessagingPushFCM.initializeForExtension(withConfig: config)
        #endif
    }
}
