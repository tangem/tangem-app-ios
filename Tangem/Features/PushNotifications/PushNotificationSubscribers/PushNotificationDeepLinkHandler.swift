//
//  PushNotificationDeepLinkHandler.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import UserNotifications

final class PushNotificationDeepLinkHandler {
    @Injected(\.incomingActionHandler) private var incomingActionHandler: IncomingActionHandler

    @MainActor
    private func handleDeeplinkIfNeeded(response: UNNotificationResponse) {
        guard let deeplinkURL = response.notification.request.content.userInfo[Constants.deeplinkKey] as? String,
              let url = URL(string: deeplinkURL)
        else {
            return
        }

        incomingActionHandler.handleDeeplink(url)
    }
}

extension PushNotificationDeepLinkHandler: PushNotificationSubscriber {
    public func handleResponse(_ response: UNNotificationResponse) {
        handleDeeplinkIfNeeded(response: response)
    }
}

extension PushNotificationDeepLinkHandler {
    enum Constants {
        static let deeplinkKey = "deeplink"
    }
}
