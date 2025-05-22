//
//  CommonPushNotificationsHandler.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import UserNotifications

final class CommonPushNotificationsHandler: NSObject {
    @Injected(\.incomingActionHandler) private var incomingActionHandler: IncomingActionHandler
    private var respondedNotificationIds: Set<String> = []
    private let deeplinkKey = "deeplink"
    
    @MainActor
    private func handleDeeplinkIfNeeded(response: UNNotificationResponse) {
        guard let deeplinkURL = response.notification.request.content.userInfo[deeplinkKey] as? String,
              let url = URL(string: deeplinkURL) else { return }
        
        incomingActionHandler.handleDeeplink(url)
    }
}

extension CommonPushNotificationsHandler: PushNotificationsHandling {
    @MainActor
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        let identifier = response.notification.request.identifier
        handleDeeplinkIfNeeded(response: response)
        
        guard response.actionIdentifier == UNNotificationDefaultActionIdentifier,
              !respondedNotificationIds.contains(identifier) else {
            return
        }
        
        respondedNotificationIds.insert(identifier)
        Analytics.log(.pushNotificationOpened)
    }
}
